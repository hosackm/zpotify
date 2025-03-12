//! This module contains definitions and methods for searching
//! using the Spotify Web API.
const std = @import("std");
const url = @import("url.zig");
const JsonResponse = @import("types.zig").JsonResponse;
const Paginated = @import("types.zig").Paginated;

const Track = @import("track.zig").Simple;
const Artist = @import("artist.zig").Simple;
const Album = @import("album.zig").Simple;
const Playlist = @import("playlist.zig").Simple;
const Show = @import("show.zig").Simple;
const Episode = @import("episode.zig").Simple;
const Audiobook = @import("audiobook.zig").Simple;
const Client = @import("client.zig").Client;

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

    const Field = enum {
        tracks,
        artists,
        albums,
        playlists,
        shows,
        episodes,
        audiobooks,
    };

    // Custom JSON parsing for objects returned from the search API endpoint.
    // https://api.spotify.com/v1/search
    pub fn jsonParse(
        alloc: std.mem.Allocator,
        source: anytype,
        opts: std.json.ParseOptions,
    ) !Result {
        // Build Result type one field at a time.
        var result = Result{};

        const value = try std.json.innerParse(std.json.Value, alloc, source, opts);
        var iter = value.object.iterator();

        while (iter.next()) |entry| {
            inline for (@typeInfo(Result).Struct.fields) |field| {
                if (std.mem.eql(u8, entry.key_ptr.*, field.name)) {
                    // Go from optional to underlying type. (ie. ?Paginated(Artist) -> Paginated(Artist))
                    const child_type = @typeInfo(field.type).Optional.child;

                    @field(result, field.name) = try std.json.parseFromValueLeaky(
                        child_type,
                        alloc,
                        entry.value_ptr.*,
                        opts,
                    );
                }
            }
        }

        return result;
    }

    // Moves a single field of a Result ahead by one page.
    // Returns true if page was sucessful otherwise false.
    // A false value can be returned if a request fails
    // OR if there is no next page available.
    pub inline fn pageForward(
        self: *Result,
        alloc: std.mem.Allocator,
        client: *Client,
        which: Field,
    ) !bool {
        var edited: bool = false;

        if (@field(self, @tagName(which))) |field| {
            if (field.next) |next_url| {
                var request = try client.get(alloc, try std.Uri.parse(next_url));
                defer request.deinit();
                const response = try JsonResponse(
                    Result,
                ).parse(alloc, &request);

                switch (response.resp) {
                    .err => edited = false,
                    .ok => |val| {
                        @field(self, @tagName(which)) = @field(val, @tagName(which));
                    },
                }
                edited = true;
            }
        }
        return edited;
    }

    // Moves a single field of a Result backward by one page.
    // Returns true if page was sucessful otherwise false.
    // A false value can be returned if a request fails
    // OR if there is no previous page available.
    pub inline fn pageBackward(
        self: *Result,
        alloc: std.mem.Allocator,
        client: *Client,
        which: Field,
    ) !bool {
        var edited: bool = false;

        if (@field(self, @tagName(which))) |field| {
            if (field.previous) |prev_url| {
                var request = try client.get(alloc, try std.Uri.parse(prev_url));
                defer request.deinit();
                const response = try JsonResponse(
                    Result,
                ).parse(alloc, &request);

                switch (response.resp) {
                    .err => edited = false,
                    .ok => |val| {
                        @field(self, @tagName(which)) = @field(val, @tagName(which));
                    },
                }
                edited = true;
            }
        }

        return edited;
    }
};

// Specifies which type of results to include in a search result.
// For fields set to true, the corresponding field in the
// Result type will be available. All other fields will be null.
//
// For example:
//  .{ .album = true, .episode = true }
// would enable albums and episode in the search results
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
    client: *Client,
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
