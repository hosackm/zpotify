const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Album = @import("album.zig");
const Track = @import("track.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;

pub usingnamespace Simplified;

followers: struct { href: ?[]const u8, total: u64 },
genres: []const []const u8,
images: []const struct { url: []const u8, height: u16, width: u16 },
popularity: u8,

pub const Simplified = struct {
    external_urls: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    name: []const u8,
    type: []const u8,
    uri: types.SpotifyUri,
};

const Self = @This();

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
) !P(Self) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/artists/{s}",
        id,
        .{},
    );
    defer alloc.free(artist_url);

    const body = try client.get(alloc, try std.Uri.parse(artist_url));
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
) !P(M(Self, "artists")) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/artists",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(artist_url);

    const body = try client.get(alloc, try std.Uri.parse(artist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        M(Self, "artists"),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const PagedAlbum = Paged(Album.Simplified);
const AlbumOpts = struct {
    include_groups: ?[]const []const u8 = null,
    market: ?[]const u8 = null,
    limit: ?u8 = null,
    offset: ?u16 = null,
};
pub fn getAlbums(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime artist_id: types.SpotifyId,
    opts: AlbumOpts,
) !P(PagedAlbum) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/artists/{s}/albums",
        artist_id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(artist_url);

    const body = try client.get(alloc, try std.Uri.parse(artist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        PagedAlbum,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getTopTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime artist_id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(M(Track.Simplified, "tracks")) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/artists/{s}/top-tracks",
        artist_id,
        .{ .market = opts.market },
    );
    defer alloc.free(artist_url);

    const body = try client.get(alloc, try std.Uri.parse(artist_url));
    defer alloc.free(body);

    std.debug.print("{s}\n", .{body});

    return try std.json.parseFromSlice(
        M(Track.Simplified, "tracks"),
        alloc,
        body,
        .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        },
    );
}
