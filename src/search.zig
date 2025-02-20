//! This module contains definitions and methods for searching
//! using the Spotify Web API.
const std = @import("std");
const url = @import("url.zig");
const JsonResponse = @import("types.zig").JsonResponse;
const Paginated = @import("types.zig").Paginated;

const Track = @import("track.zig").Simple;
const Artist = @import("artist.zig").Simple;
const Album = @import("album.zig").Simple;
const Playlist = @import("playlist.zig");
const Show = @import("show.zig").Simple;
const Episode = @import("episode.zig").Simple;
const Audiobook = @import("audiobook.zig").Simple;

// Structure for representing a search result that can contain
// resource types ranging from tracks, artists, albums, etc.
pub const Result = struct {
    tracks: ?Paginated(Track) = null,
    artists: ?Paginated(Artist) = null,
    albums: ?Paginated(Album) = null,
    playlists: ?Paginated(Playlist) = null,
    shows: ?Paginated(Show) = null,
    episodes: ?Paginated(Episode) = null,
    audiobooks: ?Paginated(Audiobook) = null,

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
        while (try s.next() != .end_of_document) continue;

        var result: Result = .{};

        const lk = std.json.parseFromValueLeaky;

        var iter = parsed.value.object.iterator();
        while (iter.next()) |entry| {
            const key = entry.key_ptr.*;
            const val = entry.value_ptr.*;
            if (std.mem.eql(u8, key, "tracks")) {
                result.tracks = try lk(
                    Paginated(Track),
                    alloc,
                    val,
                    opts,
                );
            }
            if (std.mem.eql(u8, key, "artists")) {
                result.artists = try lk(
                    Paginated(Artist),
                    alloc,
                    val,
                    opts,
                );
            }
            if (std.mem.eql(u8, key, "albums")) {
                result.albums = try lk(
                    Paginated(Album),
                    alloc,
                    val,
                    opts,
                );
            }
            if (std.mem.eql(u8, key, "episodes")) {
                result.episodes = try lk(
                    Paginated(Episode),
                    alloc,
                    val,
                    opts,
                );
            }
            if (std.mem.eql(u8, key, "playlists")) {
                result.playlists = try lk(
                    Paginated(Playlist),
                    alloc,
                    val,
                    opts,
                );
            }
            if (std.mem.eql(u8, key, "shows")) {
                result.shows = try lk(
                    Paginated(Show),
                    alloc,
                    val,
                    opts,
                );
            }
            if (std.mem.eql(u8, key, "audiobooks")) {
                result.audiobooks = try lk(
                    Paginated(Audiobook),
                    alloc,
                    val,
                    opts,
                );
            }
        }

        return result;
    }
};

// Specifies which type of results to include in a search result.
// For fields set to true, the corresponding field in the
// Result type will be available. All other fields will be null.
pub const Include = struct {
    album: bool = false,
    artist: bool = false,
    playlist: bool = false,
    track: bool = false,
    show: bool = false,
    episode: bool = false,
    audiobook: bool = false,
};

// Get Spotify catalog information about albums, artists, playlists, tracks,
// shows, episodes or audiobooks that match a keyword string. Audiobooks are
// only available within the US, UK, Canada, Ireland, New Zealand and Australia
// markets.
// https://developer.spotify.com/documentation/web-api/reference/search
//
// query - the search term
// included_types - each field of the struct enables a type of resource in the search result.
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
    included_types: Include,
    opts: struct {
        market: ?[]const u8 = null,
        limit: ?usize = null,
        offset: ?usize = null,
        include_external: ?[]const u8 = null,
    },
) !JsonResponse(Result) {
    var ts = std.ArrayList([]const u8).init(alloc);
    defer ts.deinit();

    inline for (@typeInfo(Include).Struct.fields) |field| {
        const value = @field(included_types, field.name);
        if (value) try ts.append(field.name);
    }

    const search_url = try url.build(
        alloc,
        url.base_url,
        "/search",
        null,
        .{
            .q = @as(?[]const u8, query),
            .type = @as(?[]const []const u8, ts.items),
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
