// ! Album from the web API reference
const std = @import("std");
const types = @import("types.zig");
const urls = @import("urls.zig");
const Image = @import("image.zig");
const Artist = @import("artist.zig");
const Track = @import("track.zig");

pub const Simplified = struct {
    album_type: []const u8,
    artists: []const Artist.Simplified,
    available_markets: []const []const u8,
    external_urls: std.json.Value, // use std.StringHashMap ? pack the std.json.Value object into it.
    href: []const u8,
    id: types.SpotifyId,
    images: []const Image,
    name: []const u8,
    release_date: []const u8,
    release_date_precision: []const u8,
    total_tracks: usize,
    type: []const u8,
    uri: types.SpotifyUri,
};

//
// Simplified
//
pub usingnamespace Simplified;

//
// Extensions from Simplified
//
copyrights: []const struct { text: []const u8, type: []const u8 },
genres: []const u8,
label: []const u8,
popularity: u8,
tracks: types.Paginated(Track.Simplified),

// restrictions: std.json.Value
// external_ids: std.json.Value,
// missing on artist.getTopTracks, or maybe artist.getAlbums
// album_group: []const u8,

const Self = @This();

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !std.json.Parsed(Self) {
    _ = opts;
    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/albums/{s}",
        .{id},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const ManyAlbums = struct {
    albums: []const Self,
};

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !std.json.Parsed(ManyAlbums) {
    _ = opts;

    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/albums?ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        ManyAlbums,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !std.json.Parsed(types.Paginated(Track.Simplified)) {
    _ = opts;
    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/albums/{s}/tracks",
        .{id},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        types.Paginated(Track.Simplified),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub const Saved = struct {
    added_at: []const u8,
    album: Self,
};

pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !std.json.Parsed(types.Paginated(Saved)) {
    _ = opts;

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/me/albums"),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        types.Paginated(Saved),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn save(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const body = try client.put(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/me/albums"),
        struct { ids: []const types.SpotifyId }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn delete(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const body = try client.delete(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/me/albums"),
        struct { ids: []const types.SpotifyId }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn check(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !std.json.Parsed([]bool) {
    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/me/albums/contains?ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const PaginatedSimplified = struct {
    albums: types.Paginated(Simplified),
};
pub fn newReleases(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !std.json.Parsed(PaginatedSimplified) {
    _ = opts;
    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(urls.base_url ++ "/browse/new-releases"),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        PaginatedSimplified,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
