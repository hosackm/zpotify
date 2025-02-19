//! This module contains definitions and methods for interacting with
//! Track resources from the Spotify Web API.

const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Album = @import("album.zig");
const Artist = @import("artist.zig");

pub const Simple = struct {
    // The artists who performed the track. Each artist object includes a link in
    // href to more detailed information about the artist.
    artists: []const Artist.Simple,
    // A list of the countries in which the track can be played, identified by
    // their ISO 3166-1 alpha-2 code.
    available_markets: []const []const u8,
    // The disc number (usually 1 unless the album consists of more than one disc).
    disc_number: usize,
    // The track length in milliseconds.
    duration_ms: u32,
    // Whether or not the track has explicit lyrics ( true = yes it does; false = no
    // it does not OR unknown).
    explicit: bool,
    // Known external IDs for the track.
    external_urls: std.json.Value,
    // A link to the Web API endpoint providing full details of the track.
    href: []const u8,
    // The Spotify ID for the track.
    id: types.SpotifyId,
    // Whether or not the track is from a local file.
    is_local: bool,
    // The name of the track.
    name: []const u8,
    // The number of the track. If an album has several discs, the track number is
    // the number on the specified disc.
    track_number: usize,
    // The object type: "track". Allowed values: "track"
    type: []const u8,
    // The Spotify URI for the track.
    uri: types.SpotifyUri,
    // deprecated
    // preview_url: ?[]const u8,
};

// Import simple namespace to extend
pub usingnamespace Simple;

// The album on which the track appears. The album object includes a link in
// href to full information about the album.
album: Album.Simple,
// Known external IDs for the track.
external_ids: std.json.Value,
// The popularity of the track. The value will be between 0 and 100, with 100 being the most
// popular. The popularity of a track is a value between 0 and 100, with 100 being the most popular.
// The popularity is calculated by algorithm and is based, in the most part, on the total number of
// plays the track has had and how recent those plays are. Generally speaking, songs that are being
// played a lot now will have a higher popularity than songs that were played a lot in the past.
// Duplicate tracks (e.g. the same track from a single and an album) are rated independently. Artist
// and album popularity is derived mathematically from track popularity. Note: the popularity value
// may lag actual popularity by a few days: the value is not updated in real time.
popularity: u8,
// Part of the response when Track Relinking is applied. If true, the track is playable in the
// given market. Otherwise false.
is_playable: ?bool = null,
// Part of the response when Track Relinking is applied, and the requested track has been replaced
// with different track. The track in the linked_from object contains information about the originally
// requested track.
linked_from: ?std.json.Value = null,
// Included in the response when a content restriction is applied.
restrictions: ?std.json.Value = null,

const M = types.Manyify;
const Paged = types.Paginated;
const JsonResponse = types.JsonResponse;
const Self = @This();

// Get Spotify catalog information for a single track identified by its unique Spotify ID.
// https://developer.spotify.com/documentation/web-api/reference/get-track
//
// ids - Spotify Track IDs to retrieve
// opts.market - an optional ISO 3166-1 Country Code
pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/tracks/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Self).parse(alloc, &request);
}

// Get Spotify catalog information for multiple tracks based on their Spotify IDs.
// https://developer.spotify.com/documentation/web-api/reference/get-several-tracks
//
// ids - Spotify Track IDs to retrieve
// opts.market - an optional ISO 3166-1 Country Code
pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Simple, "tracks")) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/tracks",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(M(Simple, "tracks")).parse(alloc, &request);
}

pub const Saved = struct { added_at: []const u8, track: Simple };

// Get a list of the songs saved in the current Spotify user's 'Your Music' library.
// https://developer.spotify.com/documentation/web-api/reference/get-users-saved-tracks
//
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. default: 20. minimum: 1. maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Paged(Saved)).parse(alloc, &request);
}

// Save one or more tracks to the current user's 'Your Music' library.
// https://developer.spotify.com/documentation/web-api/reference/save-tracks-user
//
// ids - Spotify Track IDs to save
pub fn save(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    var request = try client.put(alloc, try std.Uri.parse(show_url), .{});
    defer request.deinit();
}

// Remove one or more tracks from the current user's 'Your Music' library.
// https://developer.spotify.com/documentation/web-api/reference/remove-tracks-user
//
// ids - Spotify Track IDs to remove
pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    var request = try client.delete(alloc, try std.Uri.parse(show_url), .{});
    defer request.deinit();
}

// Check if one or more tracks is already saved in the current Spotify user's 'Your Music' library.
// https://developer.spotify.com/documentation/web-api/reference/check-users-saved-tracks
//
// ids - Spotify Track IDs to check if user has saved
pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    var request = try client.get(alloc, try std.Uri.parse(show_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}
