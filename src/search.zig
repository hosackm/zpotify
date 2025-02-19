//! This module contains definitions and methods for searching
//! using the Spotify Web API.
const std = @import("std");
const url = @import("url.zig");
const P = std.json.Parsed;
const JsonResponse = @import("types.zig").JsonResponse;

// Structure for representing a search result that can contain
// resource types ranging from tracks, artists, albums, etc.
pub const Result = union(enum) {
    tracks: std.json.Value,
    artists: std.json.Value,
    albums: std.json.Value,
    playlists: std.json.Value,
    shows: std.json.Value,
    episodes: std.json.Value,
    audiobooks: std.json.Value,

    pub fn jsonParse(
        alloc: std.mem.Allocator,
        s: anytype,
        opts: std.json.ParseOptions,
    ) !Result {
        const parsed = try std.json.parseFromSlice(
            std.json.Value,
            alloc,
            s.input,
            opts,
        );
        defer parsed.deinit();

        // don't need to scan input
        while (try s.next() != .end_of_document) {}

        var iter = parsed.value.object.iterator();
        const entry = iter.next().?;
        if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "tracks",
        )) {
            return .{
                .tracks = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "artists",
        )) {
            return .{
                .artists = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "albums",
        )) {
            return .{
                .albums = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "playlists",
        )) {
            return .{
                .playlists = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "episodes",
        )) {
            return .{
                .episodes = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "shows",
        )) {
            return .{
                .shows = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "audiobooks",
        )) {
            return .{
                .audiobooks = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else unreachable;
    }
};

// Different types that can be returned from the /search endpoint
pub const Type = enum {
    album,
    artist,
    playlist,
    track,
    show,
    episode,
    audiobook,
};

const Self = @This();

// Get Spotify catalog information about albums, artists, playlists, tracks,
// shows, episodes or audiobooks that match a keyword string. Audiobooks are
// only available within the US, UK, Canada, Ireland, New Zealand and Australia
// markets.
// https://developer.spotify.com/documentation/web-api/reference/search
//
// query - the search term
// search_type - the type of search to perform (tracks, episodes, artists, etc.)
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. default: 20. minimum: 1. maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
// opts.include_external - If include_external=audio is specified it signals that the client
//                         can play externally hosted audio content, and marks the content
//                         as playable in the response. By default externally hosted audio
//                         content is marked as unplayable in the response.
pub fn search(
    alloc: std.mem.Allocator,
    client: anytype,
    query: []const u8,
    search_type: Type,
    opts: struct {
        market: ?[]const u8 = null,
        limit: ?usize = null,
        offset: ?usize = null,
        include_external: ?[]const u8 = null,
    },
) !JsonResponse(Result) {
    const search_url = try url.build(
        alloc,
        url.base_url,
        "/search",
        null,
        .{
            .q = @as(?[]const u8, query),
            .type = @as(?[]const u8, @tagName(search_type)),
            .market = opts.market,
            .limit = opts.limit,
            .offset = opts.offset,
            .include_external = opts.include_external,
        },
    );
    defer alloc.free(search_url);

    var request = try client.get(alloc, try std.Uri.parse(search_url));
    defer request.deinit();
    return JsonResponse(Result).parse(alloc, &request);
}
