//! Playlists from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Track = @import("track.zig");
const Episode = @import("episode.zig");
const Paged = types.Paginated;
const P = std.json.Parsed;
const M = types.Manyify;

const Self = @This();

const TrackOrEpisode = union(enum) {
    track: Track.Simplified,
    episode: Episode.Simplified,

    pub fn jsonParse(
        alloc: std.mem.Allocator,
        s: anytype,
        opts: std.json.ParseOptions,
    ) !TrackOrEpisode {
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
        while (iter.next()) |obj| {
            std.debug.print("{s} -> {any}\n", .{ obj.key_ptr.*, obj.value_ptr.* });
        }

        std.debug.print("s.input = {s}\n", .{s.input[0..1000]});

        if (std.mem.eql(
            u8,
            // parsed.value.object.get("type").?.string,
            parsed.value.object.get("track").?.object.get("type").?.string,
            "track",
        )) {
            return .{
                .track = (try std.json.parseFromSlice(
                    Track.Simplified,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            // parsed.value.object.get("type").?.string,
            parsed.value.object.get("track").?.object.get("type").?.string,
            "episode",
        )) {
            return .{
                .episode = (try std.json.parseFromSlice(
                    Episode.Simplified,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else unreachable;
    }
};

pub const PlaylistTrack = struct {
    added_at: []const u8,
    added_by: ?std.json.Value,
    is_local: bool,
    // must parse this from the top down...
    // track: TrackOrEpisode,
};

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
    uris: ?[]const types.SpotifyUri,
    position: ?u16,

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try types.optionalStringify(
            self,
            writer,
        );
    }
};

collaborative: bool,
description: []const u8,
external_urls: std.json.Value,
href: []const u8,
id: []const u8,
name: []const u8,
owner: std.json.Value,
public: bool,
snapshot_id: []const u8,
type: []const u8,
uri: types.SpotifyUri,

// actually isn't completely paginated...
// "tracks": {
//     "href": "https://api.spotify.com/v1/playlists/0pG5NJccBHQOUj3ihujaxo/tracks",
//     "total": 0
// },
// tracks: Paged(PlaylistTrack),

primary_color: ?[]const u8 = null,
images: ?[]const Image = null,
followers: ?std.json.Value = null,

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct {
        market: ?[]const u8 = null,
        fields: ?[]const u8 = null,
        additional_types: ?[]const u8 = null,
    },
) !P(Self) {
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

    const body = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

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

    const body = try client.put(alloc, try std.Uri.parse(playlist_url), details);
    defer alloc.free(body);
}

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
) !P(Paged(PlaylistTrack)) {
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

    const body = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer alloc.free(body);

    std.debug.print("body: {s}\n", .{body});

    return try std.json.parseFromSlice(
        Paged(PlaylistTrack),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
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
pub fn update(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    insert: Update,
) !P([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    const body = try client.put(alloc, try std.Uri.parse(playlist_url), insert);
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []const u8,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn add(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    add_info: Add,
) !P([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    const body = try client.post(alloc, try std.Uri.parse(playlist_url), add_info);
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []const u8,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    rem: Remove,
) !P([]const u8) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/playlists/{s}/tracks",
        id,
        .{},
    );
    defer alloc.free(playlist_url);

    const body = try client.delete(alloc, try std.Uri.parse(playlist_url), rem);
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []const u8,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn saved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !P(Paged(Self)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/me/playlists",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(playlist_url);

    const body = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(Self),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getPlaylistsForUser(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyUserId,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !P(Paged(Self)) {
    const playlist_url = try url.build(
        alloc,
        url.base_url,
        "/users/{s}/playlists",
        id,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(playlist_url);

    const body = try client.get(alloc, try std.Uri.parse(playlist_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(Self),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
