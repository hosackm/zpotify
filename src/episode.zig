//! This module contains definitions and methods for interacting with
//! Episode resources (associated with Shows) from the Spotify Web API.
const std = @import("std");
const types = @import("types.zig");
const Show = @import("show.zig");
const Image = @import("image.zig");
const url = @import("url.zig");

pub const Simple = struct {
    // A description of the episode. HTML tags are stripped away from this
    // field, use html_description field in case HTML tags are needed.
    description: []const u8,
    // A description of the episode. This field may contain HTML tags.
    html_description: []const u8,
    // The episode length in milliseconds.
    duration_ms: u32,
    // Whether or not the episode has explicit content
    // (true = yes it does; false = no it does not OR unknown).
    explicit: bool,
    // External URLs for this episode.
    external_urls: std.json.Value,
    // A link to the Web API endpoint providing full details of the episode.
    href: []const u8,
    // The Spotify ID for the episode.
    id: types.SpotifyId,
    // The cover art for the episode in various sizes, widest first.
    images: []const Image,
    // True if the episode is hosted outside of Spotify's CDN.
    is_externally_hosted: bool,
    // The language used in the episode, identified by a ISO 639 code.
    // This field is deprecated and might be removed in the future. Please
    // use the languages field instead.
    language: []const u8,
    // A list of the languages used in the episode, identified by their ISO 639-1 code.
    languages: []const []const u8,
    // The name of the episode.
    name: []const u8,
    // The date the episode was first released, for example "1981-12-15".
    // Depending on the precision, it might be shown as "1981" or "1981-12".
    release_date: []const u8,
    // The precision with which release_date value is known. Allowed values: "year", "month", "day"
    release_date_precision: []const u8,
    // The object type. Allowed values: "episode"
    type: []const u8,
    // The Spotify URI for the episode.
    uri: types.SpotifyUri,
    // True if the episode is playable in the given market. Otherwise false.
    is_playable: ?bool = null,
    // The user's most recent position in the episode. Set if the supplied access
    // token is a user token and has the scope 'user-read-playback-position'.
    resume_point: ?types.ResumePoint = null,
    // Included in the response when a content restriction is applied.
    restrictions: ?std.json.Value = null,
};

// Include and expand on the Simple namespace.
pub usingnamespace Simple;

// The show on which the episode belongs.
show: Show.Simple,

const Self = @This();
const Paged = types.Paginated;
const M = types.Manyify;
const JsonResponse = types.JsonResponse;

// Get Spotify catalog information for a single episode identified by its unique Spotify ID.
// https://developer.spotify.com/documentation/web-api/reference/get-an-episode
//
// id - Spotify Episode ID
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
        "/episodes/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Self).parse(alloc, &request);
}

// Get Spotify catalog information for several episodes based on their Spotify IDs.
// https://developer.spotify.com/documentation/web-api/reference/get-multiple-episodes
//
// ids - Spotify Episode IDs
// opts.market - an optional ISO 3166-1 Country Code
pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Self, "episodes")) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/episodes",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(M(Self, "episodes")).parse(alloc, &request);
}

// Saved representation of an Episode
pub const Saved = struct { added_at: []const u8, episode: Self };

// Get a list of the episodes saved in the current Spotify user's library.
// This API endpoint is in beta and could change without warning.
// https://developer.spotify.com/documentation/web-api/reference/get-users-saved-episodes
//
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/episodes",
        null,
        .{
            .market = opts.market,
            .limit = opts.limit,
            .offset = opts.offset,
        },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Paged(Saved)).parse(alloc, &request);
}

// Save one or more episodes to the current user's library.
// https://developer.spotify.com/documentation/web-api/reference/save-episodes-user
//
// ids - Spotify Episode IDs to save
pub fn save(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const data: struct { ids: []const types.SpotifyId } = .{ .ids = ids };
    var request = try client.put(alloc, try std.Uri.parse(url.base_url ++ "/me/episodes"), data);
    defer request.deinit();
}

// Remove one or more episodes from the current user's library.
// https://developer.spotify.com/documentation/web-api/reference/remove-episodes-user
//
// ids - Spotify Episode IDs to remove
pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const data: struct { ids: []const types.SpotifyId } = .{ .ids = ids };
    var request = try client.delete(alloc, try std.Uri.parse(url.base_url ++ "/me/episodes"), data);
    defer request.deinit();
}

// Check if one or more episodes are already saved in the current Spotify user's library.
// Returns a slice of bools representing whether an episode is saved or not in the order
// the episode ids were provided.
// https://developer.spotify.com/documentation/web-api/reference/check-users-saved-episodes
//
// ids - Spotify Episode IDs to check
pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/episodes/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}
