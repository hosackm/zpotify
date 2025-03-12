//! This module contains definitions and methods for interacting with
//! Artist resources from the Spotify Web API.

const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Album = @import("album.zig");
const Track = @import("track.zig");
const Client = @import("client.zig").Client;

// Simplified artist representation used when included in
// another data type returned by the web api.
pub const Simple = struct {
    // Known external URLs for this artist.
    external_urls: std.json.Value,
    // A link to the Web API endpoint providing full details of the artist.
    href: []const u8,
    // The Spotify ID for the artist.
    id: types.SpotifyId,
    // The name of the artist.
    name: []const u8,
    // The object type (ie. "artist")
    type: []const u8,
    // The Spotify URI for the artist.
    uri: types.SpotifyUri,
};

// Include and expand on the Simple namespace.
pub usingnamespace Simple;

// Information about the followers of the artist.
followers: struct { href: ?[]const u8, total: u64 },
// A list of the genres the artist is associated with. If not yet
// classified, the array is empty.
genres: []const []const u8,
// Images of the artist in various sizes, widest first.
images: []const struct { url: []const u8, height: u16, width: u16 },
// The popularity of the artist. The value will be between 0 and 100, with
// 100 being the most popular. The artist's popularity is calculated from
// the popularity of all the artist's tracks.
popularity: u8,

const Self = @This();
const Paged = types.Paginated;
const M = types.Manyify;
const JsonResponse = types.JsonResponse;

// Get Spotify catalog information for a single artist identified by
// their unique Spotify ID.
// https://developer.spotify.com/documentation/web-api/reference/get-an-artist
//
// id - the Spotify Artist ID
pub fn getOne(
    alloc: std.mem.Allocator,
    client: *Client,
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

// Get Spotify catalog information for several artists based on their Spotify IDs.
// https://developer.spotify.com/documentation/web-api/reference/get-multiple-artists
//
// ids - A list of the Spotify IDs for the artists. Maximum: 50 IDs.
pub fn getMany(
    alloc: std.mem.Allocator,
    client: *Client,
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

    return JsonResponse(M(Self, "artists")).parse(alloc, &request);
}

// Get Spotify catalog information about an artist's albums.
// https://developer.spotify.com/documentation/web-api/reference/get-an-artists-albums
//
// artist_id - The Spotify ID of the artist.
// opts.include_groups: A comma-separated list of keywords that will be
//                      used to filter the response. If not supplied, all
//                      album types will be returned.
//                          Valid values are:
//                          - album
//                          - single
//                          - appears_on
//                          - compilation
//                      For example: "album,single"
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getAlbums(
    alloc: std.mem.Allocator,
    client: *Client,
    artist_id: types.SpotifyId,
    opts: struct {
        include_groups: ?[]const []const u8 = null,
        market: ?[]const u8 = null,
        limit: ?u8 = null,
        offset: ?u16 = null,
    },
) !JsonResponse(Paged(Album.Simple)) {
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
    return JsonResponse(Paged(Album.Simple)).parse(alloc, &request);
}

// Get Spotify catalog information about an artist's top tracks by country. Returns
// a JSON object with a single key "tracks" and an array of Track.Simple as the value.
// https://developer.spotify.com/documentation/web-api/reference/get-an-artists-top-tracks
//
// artist_id - The Spotify ID of the artist.
// opts.market - an optional ISO 3166-1 Country Code
pub fn getTopTracks(
    alloc: std.mem.Allocator,
    client: *Client,
    artist_id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Track.Simple, "tracks")) {
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
    return JsonResponse(M(Track.Simple, "tracks")).parse(alloc, &request);
}
