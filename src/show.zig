//! This module contains definitions and methods for interacting with
//! Show resources from the Spotify Web API.

const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Episode = @import("episode.zig");
const Client = @import("client.zig").Client;

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;
const JsonResponse = types.JsonResponse;

const Self = @This();

pub const Simple = struct {
    // A list of the countries in which the show can be played, identified by
    // their ISO 3166-1 alpha-2 code.
    available_markets: []const []const u8,
    // The copyright statements of the show.
    copyrights: []const struct { text: []const u8, type: []const u8 },
    // A description of the show. HTML tags are stripped away from this field, use
    // html_description field in case HTML tags are needed.
    description: []const u8,
    // A description of the show. This field may contain HTML tags.
    html_description: []const u8,
    // Whether or not the show has explicit content (true = yes it does; false = no
    // it does not OR unknown).
    explicit: bool,
    // External URLs for this show.
    external_urls: std.json.Value,
    // A link to the Web API endpoint providing full details of the show.
    href: []const u8,
    // The Spotify ID for the show.
    id: types.SpotifyId,
    // The cover art for the show in various sizes, widest first.
    images: []const Image,
    // True if all of the shows episodes are hosted outside of Spotify's CDN. This field
    // might be null in some cases.
    is_externally_hosted: bool,
    // A list of the languages used in the show, identified by their ISO 639 code.
    languages: []const []const u8,
    // The media type of the show.
    media_type: []const u8,
    // The name of the episode.
    name: []const u8,
    // The publisher of the show.
    publisher: []const u8,
    // The object type. Allowed values: "show"
    type: []const u8,
    // The Spotify URI for the show.
    uri: types.SpotifyUri,
    //  The total number of episodes in the show.
    total_episodes: usize,
};

// Import simple namespace to extend.
pub usingnamespace Simple;

// The episodes of the show.
episodes: Paged(?Episode.Simple),

// Get Spotify catalog information for a single show identified by its unique Spotify ID.
// https://developer.spotify.com/documentation/web-api/reference/get-a-show
//
// id - The Spotify Episode ID
// opts.market - an optional ISO 3166-1 Country Code
pub fn getOne(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Self).parse(alloc, &request);
}

// Get Spotify catalog information for several shows based on their Spotify IDs.
// https://developer.spotify.com/documentation/web-api/reference/get-multiple-shows
//
// ids - Spotify Episode IDs to retrieve
// opts.market - an optional ISO 3166-1 Country Code
pub fn getMany(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Simple, "shows")) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(M(Simple, "shows")).parse(alloc, &request);
}

// Get Spotify catalog information about an show’s episodes. Optional parameters
// can be used to limit the number of episodes returned.
// https://developer.spotify.com/documentation/web-api/reference/get-a-shows-episodes
//
// id - Spotify Show ID to retrieve Episode from
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. default: 20. minimum: 1. maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getEpisodes(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(?Episode.Simple)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows/{s}/episodes",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Paged(?Episode.Simple)).parse(alloc, &request);
}

pub const Saved = struct { added_at: []const u8, show: Simple };

// Get a list of shows saved in the current Spotify user's library. Optional parameters can be
// used to limit the number of shows returned.
// https://developer.spotify.com/documentation/web-api/reference/get-users-saved-shows
// opts.limit - maximum number of items to return. default: 20. minimum: 1. maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: *Client,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/shows",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Paged(Saved)).parse(alloc, &request);
}

// Save one or more shows to current Spotify user's library.
// https://developer.spotify.com/documentation/web-api/reference/save-shows-user
//
// ids - Spotify Show IDs to save
pub fn save(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !void {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/shows",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);
    var request = try client.put(alloc, try std.Uri.parse(show_url), .{});
    defer request.deinit();
}

// Delete one or more shows from current Spotify user's library.
// https://developer.spotify.com/documentation/web-api/reference/remove-shows-user
//
// ids - Spotify Show IDs to remove from saved episodes
pub fn remove(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !void {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/shows",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);
    var request = try client.delete(alloc, try std.Uri.parse(show_url), .{});
    defer request.deinit();
}

// Check if one or more shows is already saved in the current Spotify user's library.
// https://developer.spotify.com/documentation/web-api/reference/check-users-saved-shows
//
// ids - Spotify Show IDs to check if user has saved
pub fn contains(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/shows/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    var request = try client.get(alloc, try std.Uri.parse(show_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}
