// ! Album from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Artist = @import("artist.zig");
const Track = @import("track.zig");

pub const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;
const JsonResponse = types.JsonResponse;

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

pub usingnamespace Simplified;

copyrights: []const struct { text: []const u8, type: []const u8 },
genres: []const u8,
popularity: u8,
tracks: Paged(Track.Simplified),
external_ids: ?std.json.Value = null,
label: ?[]const u8 = null,
restrictions: ?std.json.Value = null,
album_group: ?[]const u8 = null,

const Self = @This();

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(Self).parse(alloc, &request);
}

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Self, "albums")) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(
        M(Self, "albums"),
    ).parse(alloc, &request);
}

pub fn getTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Track.Simplified)) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/albums/{s}/tracks",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(
        Paged(Track.Simplified),
    ).parse(alloc, &request);
}

pub const Saved = struct {
    added_at: []const u8,
    album: Self,
};

pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Saved)) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/me/albums",
        null,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(Paged(Saved)).parse(alloc, &request);
}
pub fn save(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    var req = try client.put(
        alloc,
        try std.Uri.parse(url.base_url ++ "/me/albums"),
        struct { ids: []const types.SpotifyId }{ .ids = ids },
    );
    defer req.deinit();
}

pub fn delete(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    var req = try client.delete(
        alloc,
        try std.Uri.parse(url.base_url ++ "/me/albums"),
        struct { ids: []const types.SpotifyId }{ .ids = ids },
    );
    defer req.deinit();
}

pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/me/albums/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(album_url);

    var request = try client.get(alloc, try std.Uri.parse(album_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}

pub const PaginatedSimpleAlbum = struct { albums: Paged(Simplified) };
pub fn newReleases(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(PaginatedSimpleAlbum) {
    const album_url = try url.build(
        alloc,
        url.base_url,
        "/browse/new-releases",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(album_url);

    var request = try client.get(
        alloc,
        try std.Uri.parse(album_url),
    );
    defer request.deinit();
    return JsonResponse(PaginatedSimpleAlbum).parse(alloc, &request);
}
