const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Album = @import("album.zig");
const Track = @import("track.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;
const JsonResponse = types.JsonResponse;

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
    id: types.SpotifyId,
) !JsonResponse(Self) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/artists/{s}",
        id,
        .{},
    );
    defer alloc.free(artist_url);

    var request = try client.get(alloc, try std.Uri.parse(artist_url));
    defer request.deinit();
    return JsonResponse(Self).parse(alloc, &request);
}

test "parse artist" {
    const files = @import("./test_data/files.zig");
    const alloc = std.testing.allocator;

    const artist = try std.json.parseFromSlice(
        Self,
        alloc,
        files.find_artist,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer artist.deinit();
}

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse(M(Self, "artists")) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/artists",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(artist_url);

    var request = try client.get(alloc, try std.Uri.parse(artist_url));
    defer request.deinit();

    return JsonResponse(
        M(Self, "artists"),
    ).parse(alloc, &request);
}

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
) !JsonResponse(Paged(Album.Simplified)) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/artists/{s}/albums",
        artist_id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(artist_url);

    var request = try client.get(alloc, try std.Uri.parse(artist_url));
    defer request.deinit();
    return JsonResponse(
        Paged(Album.Simplified),
    ).parse(alloc, &request);
}

pub fn getTopTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime artist_id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Track.Simplified, "tracks")) {
    const artist_url = try url.build(
        alloc,
        url.base_url,
        "/artists/{s}/top-tracks",
        artist_id,
        .{ .market = opts.market },
    );
    defer alloc.free(artist_url);

    var request = try client.get(alloc, try std.Uri.parse(artist_url));
    defer request.deinit();
    return JsonResponse(
        M(Track.Simplified, "tracks"),
    ).parse(alloc, &request);
}

test "parse artist top tracks" {
    const files = @import("./test_data/files.zig");
    const alloc = std.testing.allocator;

    const TopTracks = M(Track.Simplified, "tracks");

    const top_tracks = try std.json.parseFromSlice(
        TopTracks,
        alloc,
        files.artist_top_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer top_tracks.deinit();
}
