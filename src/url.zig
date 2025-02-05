const std = @import("std");
const types = @import("types.zig");

pub const base_url = "https://api.spotify.com/v1";
pub const auth_url = "https://accounts.spotify.com/authorize";
pub const token_url = "https://accounts.spotify.com/api/token";

pub const base_uri = std.Uri.parse(base_url[0..]) catch unreachable;
pub const auth_uri = std.Uri.parse(auth_url[0..]) catch unreachable;
pub const token_uri = std.Uri.parse(token_url[0..]) catch unreachable;

// Escapes a string for inclusion in a URL. Unsupported characters are converted
// to their corresponding ASCII 2 digit hex codes preceded by a %.
fn escape(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
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
pub fn build(
    alloc: std.mem.Allocator,
    comptime host: []const u8,
    comptime path: []const u8,
    comptime spotify_id: ?types.SpotifyId,
    params: anytype,
) ![]const u8 {
    var url = std.ArrayList(u8).init(alloc);
    defer url.deinit();

    try url.appendSlice(host);
    if (spotify_id) |id| {
        const interpolated = try std.fmt.allocPrint(
            alloc,
            path,
            .{id},
        );
        defer alloc.free(interpolated);
        try url.appendSlice(interpolated);
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

                            switch (opt.child) {
                                u8, u16 => {
                                    const s = try std.fmt.allocPrint(alloc, "{d}", .{value});
                                    defer alloc.free(s);
                                    try url.appendSlice(s);
                                },
                                []const u8 => {
                                    const escaped = try escape(alloc, value);
                                    defer alloc.free(escaped);
                                    try url.appendSlice(escaped);
                                },
                                []const []const u8 => {},
                                else => {},
                            }
                        }
                    },
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
