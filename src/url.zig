const std = @import("std");
const types = @import("types.zig");

pub const base_url = "https://api.spotify.com/v1";
pub const auth_url = "https://accounts.spotify.com/authorize";
pub const token_url = "https://accounts.spotify.com/api/token";

// Escapes a string for inclusion in a URL. Unsupported characters are converted
// to their corresponding ASCII 2 digit hex codes preceded by a %.
pub fn escape(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
    var list = std.ArrayList(u8).init(alloc);
    const convert: []const u8 = " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{`}~";

    for (s, 0..) |c, n| {
        const slice = s[n .. n + 1];
        if (!std.mem.containsAtLeast(u8, convert, 1, slice)) {
            try list.append(c);
            continue;
        }
        var buf: [3]u8 = undefined;
        for (try std.fmt.bufPrint(&buf, "%{X}", .{c})) |ch| try list.append(ch);
    }

    return list.toOwnedSlice();
}

// Builds a URL by combining the host, path, and query sections of the URL.
// The query argument must be a struct with any number of optional fields.
// The fields must be: ?u8, ?u16, ?[]const u8, or ?[]const []const u8.
//
// alloc - allocator to use for allocations
// host - a comptime value for the base url to use as the host
// path - the path to append to the host
// spotify_id - optional ID to be formated into the path string
// params - URL query parameters to be added to the URL. Use void (ie. {}) if none.
pub fn build(
    alloc: std.mem.Allocator,
    comptime host: []const u8,
    comptime path: []const u8,
    spotify_id: ?types.SpotifyId,
    params: anytype,
) ![]const u8 {
    var url = std.ArrayList(u8).init(alloc);
    defer url.deinit();

    try url.appendSlice(host);

    if (spotify_id) |id| {
        var buffer: [256:0]u8 = undefined;
        _ = std.mem.replace(
            u8,
            path,
            "{s}",
            id,
            &buffer,
        );
        const len = path.len + id.len - 3;
        try url.appendSlice(buffer[0..len]);
    } else {
        try url.appendSlice(path);
    }

    var num_params: usize = 0;
    const info = @typeInfo(@TypeOf(params));
    switch (info) {
        .Struct => {
            inline for (info.Struct.fields) |field| {
                switch (@typeInfo(field.type)) {
                    .Optional => |opt| {
                        if (@field(params, field.name)) |value| {
                            try url.append(if (num_params > 0) '&' else '?');
                            try url.appendSlice(field.name);
                            try url.append('=');

                            const opt_info = @typeInfo(opt.child);
                            switch (opt_info) {
                                .Int => {
                                    const s = try std.fmt.allocPrint(
                                        alloc,
                                        "{d}",
                                        .{value},
                                    );
                                    defer alloc.free(s);
                                    try url.appendSlice(s);
                                },
                                .Bool => try url.appendSlice(if (value) "true" else "false"),
                                .Pointer => {
                                    // join with commas
                                    if (opt.child == []const []const u8) {
                                        const joined = try std.mem.join(
                                            alloc,
                                            ",",
                                            value,
                                        );
                                        defer alloc.free(joined);
                                        try url.appendSlice(joined);
                                    }
                                    if (opt.child == []const u8) {
                                        const escaped = try escape(alloc, value);
                                        defer alloc.free(escaped);
                                        try url.appendSlice(escaped);
                                    }
                                },
                                else => {},
                            }
                        }
                    },
                    // ?[]const []const u8, is considered a .Pointer ¯\_(ツ)_/¯
                    .Pointer => {
                        try url.append(if (num_params > 0) '&' else '?');
                        try url.appendSlice(field.name);
                        try url.append('=');

                        const joined = try std.mem.join(
                            alloc,
                            ",",
                            @field(params, field.name),
                        );
                        defer alloc.free(joined);
                        try url.appendSlice(joined);
                    },
                    else => @compileError("must be optional."),
                }
                num_params += 1;
            }
        },
        else => @compileError("params must be struct"),
    }

    return try url.toOwnedSlice();
}

test "escape" {
    const alloc = std.testing.allocator;

    const inputs: []const struct { in: []const u8, out: []const u8 } = &.{
        .{ .in = "hello world", .out = "hello%20world" },
        .{ .in = "goodbye,space", .out = "goodbye%2Cspace" },
        .{
            .in = " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{`}~",
            .out =
            \\%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2D%2E%2F%3A%3B%3C%3D%3E%3F%40%5B%5C%5D%5E%5F%60%7B%60%7D%7E
            ,
        },
    };

    for (inputs) |input| {
        const escaped = try escape(alloc, input.in);
        defer alloc.free(escaped);

        try std.testing.expectEqualStrings(escaped, input.out);
    }
}

test "build url" {
    const alloc = std.testing.allocator;
    const P = struct {
        market: ?[]const u8 = null,
        limit: ?u8 = null,
        offset: ?u16 = null,
        id: ?[]const u8 = null,
        ids: ?[]const []const u8 = null,
    };

    {
        const params: P = .{ .market = "abc" };
        const url = try build(
            alloc,
            base_url,
            "/me/profile",
            null,
            params,
        );
        defer alloc.free(url);

        try std.testing.expect(std.mem.eql(
            u8,
            url,
            "https://api.spotify.com/v1/me/profile?market=abc",
        ));
    }
    {
        const params2: P = .{
            .market = "abc",
            .limit = 123,
        };

        const url2 = try build(
            alloc,
            base_url,
            "/me/profile",
            null,
            params2,
        );
        defer alloc.free(url2);

        try std.testing.expect(std.mem.eql(
            u8,
            url2,
            "https://api.spotify.com/v1/me/profile?market=abc&limit=123",
        ));
    }
    {
        const params3: P = .{
            .market = "abc",
            .limit = 123,
            .offset = 456,
        };

        const url3 = try build(
            alloc,
            base_url,
            "/me/profile",
            null,
            params3,
        );
        defer alloc.free(url3);

        try std.testing.expect(std.mem.eql(
            u8,
            url3,
            "https://api.spotify.com/v1/me/profile?market=abc&limit=123&offset=456",
        ));
    }
    {
        const url4 = try build(
            alloc,
            base_url,
            "/me/profile",
            null,
            .{},
        );
        defer alloc.free(url4);

        try std.testing.expect(std.mem.eql(
            u8,
            url4,
            "https://api.spotify.com/v1/me/profile",
        ));
    }
    {
        const url5 = try build(
            alloc,
            base_url,
            "/me/profile",
            null,
            .{ .ids = &.{ "one", "two", "three" } },
        );
        defer alloc.free(url5);

        try std.testing.expect(std.mem.eql(
            u8,
            url5,
            "https://api.spotify.com/v1/me/profile?ids=one,two,three",
        ));
    }
    {
        const url6 = try build(
            alloc,
            base_url,
            "/artists/{s}/albums",
            "abcdefg123456789",
            .{},
        );
        defer alloc.free(url6);

        try std.testing.expect(std.mem.eql(
            u8,
            url6,
            "https://api.spotify.com/v1/artists/abcdefg123456789/albums",
        ));
    }
}
