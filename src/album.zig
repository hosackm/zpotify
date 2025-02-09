// ! Album from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Artist = @import("artist.zig");
const Track = @import("track.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;

pub const Simplified = struct {
    album_type: []const u8,
    artists: []const Artist.Simplified,
    available_markets: []const []const u8,
    external_urls: std.json.Value,
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
tracks: Paged(Track.Simplified),
restrictions: ?std.json.Value = null,
external_ids: ?std.json.Value = null,
album_group: ?[]const u8 = null,

const Self = @This();

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(Self) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(album_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(M(Self, "albums")) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(album_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        M(Self, "albums"),
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
) !P(Paged(Track.Simplified)) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums/{s}/tracks",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(album_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(Track.Simplified),
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
) !P(Paged(Saved)) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/me/albums",
        null,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    const body = try client.get(alloc, try std.Uri.parse(album_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(Saved),
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
        try std.Uri.parse(url.base_url ++ "/me/albums"),
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
        try std.Uri.parse(url.base_url ++ "/me/albums"),
        struct { ids: []const types.SpotifyId }{ .ids = ids },
    );
    defer alloc.free(body);
}

pub fn check(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !P([]bool) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/me/albums/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(album_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(album_url),
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
    albums: Paged(Simplified),
};
pub fn newReleases(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !P(PaginatedSimplified) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/browse/new-releases",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(album_url);
    const body = try client.get(alloc, try std.Uri.parse(album_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        PaginatedSimplified,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
