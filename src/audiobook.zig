//! This module contains definitions and methods for interacting with
//! Album resources from the Spotify Web API.  Audiobooks
// are only available within the US, UK, Canada, Ireland, New Zealand
// and Australia markets.

const std = @import("std");
const types = @import("types.zig");
const Image = @import("image.zig");
const Chapter = @import("chapter.zig");
const url = @import("url.zig");
const Client = @import("client.zig").Client;

// Simplified album representation used when included in
// another data type returned by the web api.
pub const Simple = struct {
    // The author(s) for the audiobook.
    authors: []const struct { name: []const u8 },
    // A list of the countries in which the audiobook can be played,
    // identified by their ISO 3166-1 alpha-2 code.
    available_markets: []const []const u8,
    // The copyright statements of the audiobook.
    copyrights: []const struct { text: []const u8, type: []const u8 },
    // A description of the audiobook. HTML tags are stripped away from this field,
    // use html_description field in case HTML tags are needed.
    description: []const u8,
    // The edition of the audiobook. Example: "Unabridged"
    edition: []const u8,
    // Whether or not the audiobook has explicit content
    // (true = yes it does; false = no it does not OR unknown).
    explicit: bool,
    // A description of the audiobook. This field may contain HTML tags.
    html_description: []const u8,
    // External URLs for this audiobook.
    external_urls: std.json.Value,
    // A link to the Web API endpoint providing full details of the audiobook.
    href: []const u8,
    // The Spotify ID for the audiobook.
    id: types.SpotifyId,
    // The cover art for the audiobook in various sizes, widest first.
    images: []const Image,
    // A list of the languages used in the audiobook, identified by their ISO 639 code.
    languages: []const []const u8,
    // The media type of the audiobook.
    media_type: []const u8,
    // The name of the audiobook.
    name: []const u8,
    // The narrator(s) for the audiobook.
    narrators: []const struct { name: []const u8 },
    // The publisher of the audiobook.
    publisher: []const u8,
    // The object type. Allowed values: "audiobook"
    type: []const u8,
    // The Spotify URI for the audiobook.
    uri: types.SpotifyUri,
    // The number of chapters in this audiobook.
    total_chapters: u16,
};

// Include and expand on the Simple namespace.
pub usingnamespace Simple;

// The chapters of the audiobook.
chapters: Paged(Chapter),

const Self = @This();
const Paged = types.Paginated;
const M = types.Manyify;
const JsonResponse = types.JsonResponse;

// Get Spotify catalog information for a single audiobook. Audiobooks
// are only available within the US, UK, Canada, Ireland, New Zealand
// and Australia markets.
// https://developer.spotify.com/documentation/web-api/reference/get-an-audiobook
//
// id - the Spotify Audiobook ID
// opts.market - an optional ISO 3166-1 Country Code
pub fn getOne(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse(Self).parseRequest(alloc, &request);
}

// Get Spotify catalog information for several audiobooks identified by their
// Spotify IDs.
// https://developer.spotify.com/documentation/web-api/reference/get-an-audiobook
//
// id - the Spotify Audiobook ID
// opts.market - an optional ISO 3166-1 Country Code
pub fn getMany(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Self, "audiobooks")) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse(M(Self, "audiobooks")).parseRequest(alloc, &request);
}

// Get Spotify catalog information about an audiobook's chapters.
// https://developer.spotify.com/documentation/web-api/reference/get-an-artists-albums
//
// id - The Spotify ID of the audiobook.
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getChapters(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u16 = null },
) !JsonResponse(Paged(Chapter)) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks/{s}/chapters",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse(Paged(Chapter)).parseRequest(alloc, &request);
}

// Get a list of the audiobooks saved in the current Spotify user's 'Your Music' library.
// https://developer.spotify.com/documentation/web-api/reference/get-users-saved-audiobooks
//
// id - a Spotify Audiobook ID ie. "7iHfbu1YPACw6oZPAFJtqe"
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: *Client,
    opts: struct { limit: ?u8 = null, offset: ?u16 = null },
) !JsonResponse(Paged(Simple)) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse(Paged(Simple)).parseRequest(alloc, &request);
}

// Save one or more audibooks to the current user's 'Your Music' library.
//
// https://developer.spotify.com/documentation/web-api/reference/save-audiobooks-user
//
// ids - Spotify Audiobook IDs to save, ie: &.{"18yVqkdbdRvS24c0Ilj2ci", "1HGw3J3NxZO1TP1BTtVhpZ"}
pub fn save(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !void {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(audiobook_url);
    var req = try client.put(alloc, try std.Uri.parse(audiobook_url), .{});
    defer req.deinit();
}

// Remove one or more audiobooks from the Spotify user's library.
// https://developer.spotify.com/documentation/web-api/reference/remove-audiobooks-user
//
// ids - Spotify IDs of audiboooks to save
pub fn remove(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !void {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(audiobook_url);

    var req = try client.delete(alloc, try std.Uri.parse(audiobook_url), .{});
    defer req.deinit();
}

// Check if one or more audiobooks are already saved in the current Spotify user's library.
// Returns a slice of bools representing whether a book is saved or not in the order
// the audiobook ids were provided.
// https://developer.spotify.com/documentation/web-api/reference/check-users-saved-audiobooks
//
// ids - Spotify IDs of possibly saved audiobooks
pub fn contains(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse([]bool).parseRequest(alloc, &request);
}
