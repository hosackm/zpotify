//! This module contains definitions and methods for interacting with
//! Playlist resources from the Spotify Web API.

const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Track = @import("track.zig");
const Episode = @import("episode.zig");

pub const Simple = struct {
    // true if the owner allows other users to modify the playlist.
    collaborative: bool,
    // The playlist description. Only returned for modified, verified
    // playlists, otherwise null.
    description: ?[]const u8,
    // Known external URLs for this playlist.
    external_urls: std.json.Value,
    // A link to the Web API endpoint providing full details of the playlist.
    href: []const u8,
    // The Spotify ID for the playlist.
    // id: []const u8,
    // Images for the playlist. The array may be empty or contain up t
    // three images. The images are returned by size in descending order.
    // See Working with Playlists. Note: If returned, the source URL for
    // the image (url) is temporary and will expire in less than a day.
    images: ?[]const Image = null,
    // The name of the playlist.
    name: []const u8,
    // The user who owns the playlist
    owner: std.json.Value,
    // The playlist's public/private status (if it is added to the user's profile):
    // true the playlist is public, false the playlist is private, null the
    // playlist status is not relevant. For more about public/private status
    public: ?bool,
    // The version identifier for the current playlist. Can be supplied in
    // other requests to target a specific playlist version
    snapshot_id: []const u8,
    // The object type: "playlist"
    type: []const u8,
    // The Spotify URI for the playlist.
    uri: types.SpotifyUri,
    // The primary color used when displaying the playlist
    primary_color: ?[]const u8 = null,
    // Information about the followers of the playlist.
    followers: ?std.json.Value = null,
    // When returned in other contexts not all paged fields are available
    tracks: ?struct { href: []const u8, total: u32 } = null,
};

// Figure out why pub usingnamespace isn't working for this one particularly
pub const Full = struct {
    // Import namespace and extend, NOT WORKING (perhaps it's from tracks namespace clash?)
    // pub usingnamespace Simple;

    // true if the owner allows other users to modify the playlist.
    collaborative: bool,
    // The playlist description. Only returned for modified, verified
    // playlists, otherwise null.
    description: ?[]const u8,
    // Known external URLs for this playlist.
    external_urls: std.json.Value,
    // A link to the Web API endpoint providing full details of the playlist.
    href: []const u8,
    // The Spotify ID for the playlist.
    // id: []const u8,
    // Images for the playlist. The array may be empty or contain up t
    // three images. The images are returned by size in descending order.
    // See Working with Playlists. Note: If returned, the source URL for
    // the image (url) is temporary and will expire in less than a day.
    images: ?[]const Image = null,
    // The name of the playlist.
    name: []const u8,
    // The user who owns the playlist
    owner: std.json.Value,
    // The playlist's public/private status (if it is added to the user's profile):
    // true the playlist is public, false the playlist is private, null the
    // playlist status is not relevant. For more about public/private status
    public: ?bool,
    // The version identifier for the current playlist. Can be supplied in
    // other requests to target a specific playlist version
    snapshot_id: []const u8,
    // The object type: "playlist"
    type: []const u8,
    // The Spotify URI for the playlist.
    uri: types.SpotifyUri,
    // The primary color used when displaying the playlist
    primary_color: ?[]const u8 = null,
    // Information about the followers of the playlist.
    followers: ?std.json.Value = null,
    // the actual tracks
    tracks: Paged(PlaylistTrack),

    pub fn jsonParse(
        a: std.mem.Allocator,
        source: *std.json.Scanner,
        opts: std.json.ParseOptions,
    ) !Full {
        const parsed = try std.json.parseFromSlice(
            std.json.Value,
            a,
            source.input,
            opts,
        );
        defer parsed.deinit();

        while (try source.next() != .end_of_document) continue;

        const obj = parsed.value.object;

        return .{
            .collaborative = obj.get("collaborative").?.bool,
            .description = if (obj.get("description")) |d| d.string else null,
            .external_urls = obj.get("external_urls").?,
            .href = obj.get("href").?.string,
            .name = obj.get("name").?.string,
            .owner = obj.get("owner").?,
            .public = if (obj.get("public")) |d| d.bool else null,
            .snapshot_id = obj.get("snapshot_id").?.string,
            .type = obj.get("type").?.string,
            .uri = obj.get("uri").?.string,
            .tracks = try std.json.parseFromValueLeaky(
                Paged(PlaylistTrack),
                a,
                obj.get("tracks").?,
                opts,
            ),
        };
    }
};

// Tracks from the playlist
const Paged = types.Paginated;
const M = types.Manyify;
const JsonResponse = types.JsonResponse;

pub const PlaylistTrack = struct {
    added_at: []const u8,
    added_by: ?std.json.Value,
    is_local: bool,
    track: Content,

    // The content within a track can be either a track (ie. music), or
    // episode (ie. a podcast)
    pub const Content = union(enum) {
        track: Track.Simple,
        episode: Episode.Simple,

        pub fn jsonParse(
            alloc: std.mem.Allocator,
            source: *std.json.Scanner,
            opts: std.json.ParseOptions,
        ) !Content {
            const v = try std.json.parseFromTokenSourceLeaky(
                std.json.Value,
                alloc,
                source,
                opts,
            );

            return if (std.mem.eql(u8, v.object.get("type").?.string, "track"))
                .{
                    .track = try std.json.parseFromValueLeaky(
                        Track.Simple,
                        alloc,
                        v,
                        opts,
                    ),
                }
            else
                .{
                    .episode = try std.json.parseFromValueLeaky(
                        Episode.Simple,
                        alloc,
                        v,
                        opts,
                    ),
                };
        }
    };

    pub fn jsonParse(
        alloc: std.mem.Allocator,
        source: *std.json.Scanner,
        opts: std.json.ParseOptions,
    ) !PlaylistTrack {
        var pt: PlaylistTrack = undefined;

        if (try source.next() != .object_begin) return error.UnexpectedToken;

        while (true) {
            switch (try source.nextAlloc(alloc, .alloc_if_needed)) {
                .string, .allocated_string => |field| {
                    if (std.mem.eql(u8, field, "added_at")) {
                        pt.added_at = switch (try source.nextAlloc(alloc, opts.allocate.?)) {
                            .string, .allocated_string => |s| s,
                            else => return error.UnexpectedToken,
                        };
                    } else if (std.mem.eql(u8, field, "added_by")) {
                        pt.added_by = try std.json.parseFromTokenSourceLeaky(
                            std.json.Value,
                            alloc,
                            source,
                            opts,
                        );
                    } else if (std.mem.eql(u8, field, "is_local")) {
                        pt.is_local = switch (try source.nextAlloc(alloc, opts.allocate.?)) {
                            .true => true,
                            .false => false,
                            else => return error.UnexpectedToken,
                        };
                    } else if (std.mem.eql(u8, field, "track")) {
                        pt.track = try std.json.parseFromTokenSourceLeaky(
                            Content,
                            alloc,
                            source,
                            opts,
                        );
                    } else {
                        // skip ones we don't recognize... (ie. video_thumbnail)
                        try source.skipValue();
                    }
                },
                .object_end => break,
                else => return error.UnexpectedToken,
            }
        }

        return pt;
    }

    pub fn jsonParseFromValue(
        alloc: std.mem.Allocator,
        value: std.json.Value,
        opts: std.json.ParseOptions,
    ) !PlaylistTrack {
        switch (value) {
            .object => |obj| {
                // const obj = source.object;
                const track = obj.get("track").?;
                const track_type = track.object.get("type").?.string;

                return .{
                    .added_at = obj.get("added_at").?.string,
                    .added_by = obj.get("added_by"),
                    .is_local = obj.get("is_local").?.bool,
                    .track = if (std.mem.eql(u8, track_type, "track"))
                        @unionInit(
                            Content,
                            "track",
                            try std.json.parseFromValueLeaky(
                                Track.Simple,
                                alloc,
                                obj.get("track").?,
                                opts,
                            ),
                        )
                    else
                        @unionInit(
                            Content,
                            "episode",
                            try std.json.parseFromValueLeaky(
                                Episode.Simple,
                                alloc,
                                obj.get("track").?,
                                opts,
                            ),
                        ),
                };
            },
            else => unreachable,
        }
    }
    // primary color null
    // video thumbnail { url: null }
};

pub fn jsonParse(a: std.mem.Allocator, source: *std.json.Scanner, opts: std.json.ParseOptions) !Full {
    const parsed = try std.json.parseFromSlice(std.json.Value, a, source.input, opts);
    defer parsed.deinit();

    while (try source.next() != .end_of_document) continue;

    const obj = parsed.value.object;

    return .{
        .collaborative = obj.get("collaborative").?.bool,
        .description = if (obj.get("description")) |d| d.string else null,
        .external_urls = obj.get("external_urls").?,
        .href = obj.get("href").?.string,
        .name = obj.get("name").?.string,
        .owner = obj.get("owner").?,
        .public = if (obj.get("public")) |d| d.bool else null,
        .snapshot_id = obj.get("snapshot_id").?.string,
        .type = obj.get("type").?.string,
        .uri = obj.get("uri").?.string,
        .tracks = try std.json.parseFromValueLeaky(
            Paged(PlaylistTrack),
            a,
            obj.get("tracks").?,
            opts,
        ),
    };
}

pub const Details = struct {
    // The new name for the playlist,
    name: ?[]const u8 = null,

    // The playlist's public/private status (if it should be added to
    // the user's profile or not): true the playlist will be public,
    // false the playlist will be private, null the playlist status
    // is not relevant.
    public: ?bool = null,

    // If true, the playlist will become collaborative and other users
    // will be able to modify the playlist in their Spotify client.
    collaborative: ?bool = null,

    // Value for playlist description as displayed in Spotify Clients and in the Web API.
    description: ?[]const u8 = null,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

pub const Update = struct {
    // URI of items to update
    uris: ?[]const types.SpotifyUri = null,

    //The position of the first item to be reordered.
    range_start: ?u16 = null,

    // The position where the items should be inserted.
    // To reorder the items to the end of the playlist, simply set insert_before
    // to the position after the last item.
    // Examples:
    // To reorder the first item to the last position in a playlist with 10 items,
    // set range_start to 0, and insert_before to 10.
    // To reorder the last item in a playlist with 10 items to the start of the playlist,
    // set range_start to 9, and insert_before to 0.
    insert_before: ?u16 = null,

    // The amount of items to be reordered. Defaults to 1 if not set.
    // The range of items to be reordered begins from the range_start position,
    // and includes the range_length subsequent items.
    // Example:
    // To move the items at index 9-10 to the start of the playlist, range_start
    // is set to 9, and range_length is set to 2.
    range_length: ?u16 = null,

    // The playlist's snapshot ID against which you want to make the changes.
    snapshot_id: ?[]const u8 = null,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

const Remove = struct {
    // An array of objects containing Spotify URIs of the tracks or episodes to remove.
    // For example:
    // { "tracks": [
    //      { "uri": "spotify:track:4iV5W9uYEdYUVa79Axb7Rh" },
    //      { "uri": "spotify:track:1301WleyT98MSxVHPZCA6M" }
    // ]}
    // A maximum of 100 objects can be sent at once.
    tracks: []const types.SpotifyUri,

    // The playlist's snapshot ID against which you want to make the changes.
    // The API will validate that the specified items exist and in the specified
    // positions and make the changes, even if more recent changes have
    // been made to the playlist.
    snapshot_id: []const u8,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

pub const Add = struct {
    // A JSON array of the Spotify URIs to add. For example:
    // {"uris": ["spotify:track:4iV5W9uYEdYUVa79Axb7Rh",
    //    "spotify:track:1301WleyT98MSxVHPZCA6M",
    //    "spotify:episode:512ojhOuo1ktJprKbVcKyQ"]
    // }
    // A maximum of 100 items can be added in one request. Note: if the uris
    // parameter is present in the query string, any URIs listed here in the
    // body will be ignored.
    uris: ?[]const types.SpotifyUri,
    // The position to insert the items, a zero-based index. For example, to insert the
    // items in the first position: position=0 ; to insert the items in the
    // third position: position=2. If omitted, the items will be appended to the playlist.
    // Items are added in the order they appear in the uris array. For example:
    // {
    //   "uris": ["spotify:track:4iV5W9uYEdYUVa79Axb7Rh","spotify:track:1301WleyT98MSxVHPZCA6M"],
    //   "position": 3
    // }
    position: ?u16,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

// Get a playlist owned by a Spotify user.
// https://developer.spotify.com/documentation/web-api/reference/get-playlist
//
// id - Spotify Playlist ID
// opts.market - an optional ISO 3166-1 Country Code
// opts.additional_types - A comma-separated list of item types that your client
//                         supports besides the default track type. Valid types
//                         are: track and episode.
// opts.fields - Filters for the query: a comma-separated list of the fields to
//               return. If omitted, all fields are returned. For example,
//               to get just the playlist''s description and URI: fields=description,uri.
//               A dot separator can be used to specify non-reoccurring fields, while
//               parentheses can be used to specify reoccurring fields within objects.
//               For example, to get just the added date and user ID of the adder:
//               fields=tracks.items(added_at,added_by.id). Use multiple parentheses to
//               drill down into nested objects, for example:
//               fields=tracks.items(track(name,href,album(name,href))).
//               Fields can be excluded by prefixing them with an exclamation mark, for
//               example: fields=tracks.items(track(name,href,album(!name,href)))
pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct {
        market: ?[]const u8 = null,
        fields: ?[]const u8 = null,
        additional_types: ?[]const u8 = null,
    },
) !JsonResponse(Full) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    var request = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer request.deinit();
    return JsonResponse(Full).parse(alloc, &request);
}

// Change a playlist's name and public/private state. (The user must, of course, own the playlist.)
// https://developer.spotify.com/documentation/web-api/reference/change-playlist-details
//
// id - Spotify Playlist ID
// details - updated details to be set on the playlist
pub fn setDetails(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    details: Details,
) !void {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    var request = try client.put(alloc, try std.Uri.parse(playlist_url), details);
    defer request.deinit();
}

// Get full details of the items of a playlist owned by a Spotify user.
// https://developer.spotify.com/documentation/web-api/reference/get-playlists-tracks
//
// id - Spotify Playlist ID
// opts.market - an optional ISO 3166-1 Country Code
// opts.additional_types - A comma-separated list of item types that your client
//                         supports besides the default track type. Valid types
//                         are: track and episode.
// opts.fields - Filters for the query: a comma-separated list of the fields to
//               return. If omitted, all fields are returned. For example,
//               to get just the playlist''s description and URI: fields=description,uri.
//               A dot separator can be used to specify non-reoccurring fields, while
//               parentheses can be used to specify reoccurring fields within objects.
//               For example, to get just the added date and user ID of the adder:
//               fields=tracks.items(added_at,added_by.id). Use multiple parentheses to
//               drill down into nested objects, for example:
//               fields=tracks.items(track(name,href,album(name,href))).
//               Fields can be excluded by prefixing them with an exclamation mark, for
//               example: fields=tracks.items(track(name,href,album(!name,href)))
// opts.limit - maximum number of items to return. default: 20. minimum: 1. maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct {
        market: ?[]const u8 = null,
        fields: ?[]const u8 = null,
        limit: ?u16 = null,
        offset: ?u16 = null,
        additional_types: ?[]const u8 = null,
    },
) !JsonResponse(Paged(PlaylistTrack)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{
            .market = opts.market,
            .fields = opts.fields,
            .additional_types = opts.additional_types,
        },
    );
    defer alloc.free(playlist_url);

    var request = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer request.deinit();
    return JsonResponse(Paged(PlaylistTrack)).parse(alloc, &request);
}

// Either reorder or replace items in a playlist depending on the request's parameters.
//
// To reorder items, include range_start, insert_before, range_length and snapshot_id
// in the request's body.
//
// To replace items, include uris as either a query parameter or in the request's body.
//
// Replacing items in a playlist will overwrite its existing items. This operation
// can be used for replacing or clearing items in a playlist.
// https://developer.spotify.com/documentation/web-api/reference/reorder-or-replace-playlists-tracks
pub fn update(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    insert: Update,
) !JsonResponse([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    var request = try client.put(alloc, try std.Uri.parse(playlist_url), insert);
    defer request.deinit();
    return JsonResponse([]const u8).parse(alloc, &request);
}

// Add one or more items to a user's playlist.
// https://developer.spotify.com/documentation/web-api/reference/add-tracks-to-playlist
//
// id - Spotify Playlist ID
// add_info -
pub fn add(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    add_info: Add,
) !JsonResponse([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    var request = try client.post(alloc, try std.Uri.parse(playlist_url), add_info);
    defer request.deinit();
    return JsonResponse([]const u8).parse(alloc, &request);
}

// Remove one or more items from a user's playlist.
// https://developer.spotify.com/documentation/web-api/reference/remove-tracks-playlist
//
// id - Spotify Playlist ID
// remove - options to define how to remove items from the playlist
pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    rem: Remove,
) !JsonResponse([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    var request = try client.delete(alloc, try std.Uri.parse(playlist_url), rem);
    defer request.deinit();
    return JsonResponse([]const u8).parse(alloc, &request);
}

// Get a list of the playlists owned or followed by the current Spotify user.
// https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists
//
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn saved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Simple)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/me/playlists",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(playlist_url);

    var request = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer request.deinit();
    return JsonResponse(Paged(Simple)).parse(alloc, &request);
}

// Get a list of the playlists owned or followed by a Spotify user.
// https://developer.spotify.com/documentation/web-api/reference/get-list-users-playlists
//
// id - the Spotify User's ID
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
pub fn getPlaylistsForUser(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyUserId,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Simple)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/users/{s}/playlists",
        id,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(playlist_url);

    var request = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer request.deinit();
    return JsonResponse(Paged(Simple)).parse(alloc, &request);
}
