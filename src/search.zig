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

const TracksResult = struct { tracks: Paginated(Track) };
const ArtistsResult = struct { artists: Paginated(Artist) };
const AlbumsResult = struct { albums: Paginated(Album) };
const PlaylistsResult = struct { playlists: Paginated(Playlist) };
const ShowsResult = struct { shows: Paginated(Show) };
const EpisodesResult = struct { episodes: Paginated(Episode) };
const AudiobooksResult = struct { audiobooks: Paginated(Audiobook) };

// Structure for representing a search result that can contain
// resource types ranging from tracks, artists, albums, etc.
pub const Result = union(enum) {
    tracks: Paginated(Track),
    artists: Paginated(Artist),
    albums: Paginated(Album),
    playlists: Paginated(Playlist),
    shows: Paginated(Show),
    episodes: Paginated(Episode),
    audiobooks: Paginated(Audiobook),

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

        const key = parsed.value.object.iterator().keys[0];
        const leaky = std.json.parseFromSliceLeaky;

        return if (std.mem.eql(u8, key, "tracks"))
            .{ .tracks = (try leaky(TracksResult, alloc, s.input, opts)).tracks }
        else if (std.mem.eql(u8, key, "artists"))
            .{ .artists = (try leaky(ArtistsResult, alloc, s.input, opts)).artists }
        else if (std.mem.eql(u8, key, "albums"))
            .{ .albums = (try leaky(AlbumsResult, alloc, s.input, opts)).albums }
        else if (std.mem.eql(u8, key, "episodes"))
            .{ .episodes = (try leaky(EpisodesResult, alloc, s.input, opts)).episodes }
        else if (std.mem.eql(u8, key, "shows"))
            .{ .shows = (try leaky(ShowsResult, alloc, s.input, opts)).shows }
        else if (std.mem.eql(u8, key, "audiobooks"))
            .{ .audiobooks = (try leaky(AudiobooksResult, alloc, s.input, opts)).audiobooks }
        else
            unreachable;
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
