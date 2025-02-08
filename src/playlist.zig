//! Playlists from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Track = @import("track.zig");
const Episode = @import("episode.zig");
const Paged = types.Paginated;
const P = std.json.Parsed;
const M = types.Manyify;

const Self = @This();

const TrackOrEpisode = union(enum) {
    track: Track.Simplified,
    episode: Episode.Simplified,

    pub fn jsonParse(
        alloc: std.mem.Allocator,
        s: anytype,
        opts: std.json.ParseOptions,
    ) !TrackOrEpisode {
        const parsed = try std.json.parseFromSlice(
            std.json.Value,
            alloc,
            s.input,
            opts,
        );
        defer parsed.deinit();

        // don't need to scan input
        while (try s.next() != .end_of_document) {}

        var iter = parsed.value.object.iterator();
        while (iter.next()) |obj| {
            std.debug.print("{s} -> {any}\n", .{ obj.key_ptr.*, obj.value_ptr.* });
        }

        std.debug.print("s.input = {s}\n", .{s.input[0..1000]});

        if (std.mem.eql(
            u8,
            // parsed.value.object.get("type").?.string,
            parsed.value.object.get("track").?.object.get("type").?.string,
            "track",
        )) {
            return .{
                .track = (try std.json.parseFromSlice(
                    Track.Simplified,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            // parsed.value.object.get("type").?.string,
            parsed.value.object.get("track").?.object.get("type").?.string,
            "episode",
        )) {
            return .{
                .episode = (try std.json.parseFromSlice(
                    Episode.Simplified,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else unreachable;
    }
};

pub const PlaylistTrack = struct {
    added_at: []const u8,
    added_by: ?std.json.Value,
    is_local: bool,
    // must parse this from the top down...
    // track: TrackOrEpisode,
};

pub const Details = struct {
    name: ?[]const u8 = null,
    public: ?bool = null,
    collaborative: ?bool = null,
    description: ?[]const u8 = null,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

pub const Insert = struct {
    uris: ?[]const types.SpotifyUri = null,
    range_start: ?u16 = null,
    insert_before: ?u16 = null,
    range_length: ?u16 = null,
    snapshot_id: ?[]const u8 = null,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

pub const Add = struct {
    uris: ?[]const types.SpotifyUri,
    position: ?u16,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

pub const Remove = struct {
    tracks: ?[]const types.SpotifyUri = null,
    snapshot_id: ?[]const u8 = null,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

collaborative: bool,
description: []const u8,
external_urls: std.json.Value,
followers: std.json.Value,
href: []const u8,
id: []const u8,
images: []const Image,
name: []const u8,
owner: std.json.Value,
public: bool,
// primary_color: ?[]const u8,
snapshot_id: []const u8,
tracks: Paged(PlaylistTrack),
type: []const u8,
uri: types.SpotifyUri,

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct {
        market: ?[]const u8 = null,
        fields: ?[]const u8 = null,
        additional_types: ?[]const u8 = null,
    },
) !P(Self) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    const body = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn setDetails(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    details: Details,
) !void {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    const body = try client.put(alloc, try std.Uri.parse(playlist_url), details);
    defer alloc.free(body);
}

pub fn getTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct {
        market: ?[]const u8 = null,
        fields: ?[]const u8 = null,
        limit: ?u16 = null,
        offset: ?u16 = null,
        additional_types: ?[]const u8 = null,
    },
) !P(Paged(PlaylistTrack)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    const body = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer alloc.free(body);

    std.debug.print("body: {s}\n", .{body});

    return try std.json.parseFromSlice(
        Paged(PlaylistTrack),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn update(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { uris: []const types.SpotifyUri },
    insert: Insert,
) !P(Paged(PlaylistTrack)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    _ = insert;
    const body = try client.put(alloc, try std.Uri.parse(playlist_url), .{});
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(PlaylistTrack),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn add(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { uris: []const types.SpotifyUri },
    info: Add,
) !P([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    _ = info;
    const body = try client.put(alloc, try std.Uri.parse(playlist_url), .{});
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []const u8,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { uris: []const types.SpotifyUri },
    rem: Remove,
) !P([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    _ = rem;
    const body = try client.put(alloc, try std.Uri.parse(playlist_url), .{});
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []const u8,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

test "test optional details serialization" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();

    const expected: []const struct { input: Details, output: []const u8 } = &.{
        .{
            .input = .{ .collaborative = true, .description = "this is a description", .name = "a name", .public = true },
            .output =
            \\{"name":"a name","public":true,"collaborative":true,"description":"this is a description"}
            ,
        },
        .{
            .input = .{ .collaborative = true, .name = "a name", .public = true },
            .output =
            \\{"name":"a name","public":true,"collaborative":true}
            ,
        },
        .{
            .input = .{ .name = "a name", .public = true },
            .output =
            \\{"name":"a name","public":true}
            ,
        },
        .{
            .input = .{ .name = "a name" },
            .output =
            \\{"name":"a name"}
            ,
        },
    };

    for (expected) |exp| {
        list.clearAndFree();
        try std.json.stringify(exp.input, .{}, list.writer());
        try std.testing.expect(std.mem.eql(u8, list.items, exp.output));
    }
}

test "test optional insert serialization" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();

    const expected: []const struct { input: Insert, output: []const u8 } = &.{
        .{
            .input = .{ .insert_before = 123, .range_length = 456, .range_start = 789, .snapshot_id = "abcdefg", .uris = &.{ "xyz", "789" } },
            .output =
            \\{"uris":["xyz","789"],"range_start":789,"insert_before":123,"range_length":456,"snapshot_id":"abcdefg"}
            ,
        },
        .{
            .input = .{ .insert_before = 123, .range_length = 456, .range_start = 789, .uris = &.{ "xyz", "789" } },
            .output =
            \\{"uris":["xyz","789"],"range_start":789,"insert_before":123,"range_length":456}
            ,
        },
        .{
            .input = .{ .insert_before = 123, .range_start = 789, .uris = &.{ "xyz", "789" } },
            .output =
            \\{"uris":["xyz","789"],"range_start":789,"insert_before":123}
            ,
        },
        .{
            .input = .{ .range_start = 789, .uris = &.{ "xyz", "789" } },
            .output =
            \\{"uris":["xyz","789"],"range_start":789}
            ,
        },
        .{
            .input = .{ .uris = &.{ "xyz", "789" } },
            .output =
            \\{"uris":["xyz","789"]}
            ,
        },
    };

    for (expected) |exp| {
        list.clearAndFree();
        try std.json.stringify(exp.input, .{}, list.writer());
        try std.testing.expect(std.mem.eql(u8, list.items, exp.output));
    }
}
