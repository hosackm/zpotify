const std = @import("std");
const types = @import("types.zig");
const urls = @import("url.zig");
const Album = @import("album.zig");
const Track = @import("track.zig");

pub usingnamespace Simplified;

followers: struct { href: ?[]const u8, total: u64 },
genres: []const []const u8,
images: []const struct { url: []const u8, height: u16, width: u16 },
popularity: u8,

pub const Simplified = struct {
    external_urls: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    name: []const u8,
    type: []const u8,
    uri: types.SpotifyUri,
};

const Self = @This();

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
) !std.json.Parsed(Self) {
    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/artists/{s}",
        .{id},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const ManyArtists = struct { artists: []const Self };

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !std.json.Parsed(ManyArtists) {
    const joined = try std.mem.join(
        alloc,
        "%2C",
        ids,
    );
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/artists?ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        ManyArtists,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const PagedAlbum = types.Paginated(Album.Simplified);
const AlbumOpts = struct {
    include_groups: ?[]const []const u8 = null,
    market: ?[]const u8 = null,
    limit: ?u8 = null,
    offset: ?u16 = null,
};
pub fn getAlbums(
    alloc: std.mem.Allocator,
    client: anytype,
    artist_id: types.SpotifyId,
    opts: AlbumOpts,
) !std.json.Parsed(PagedAlbum) {
    _ = opts;
    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/artists/{s}/albums",
        .{artist_id},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        PagedAlbum,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const ManyTracks = struct { tracks: []const Track.Simplified };
pub fn getTopTracks(
    alloc: std.mem.Allocator,
    client: anytype,
    artist_id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !std.json.Parsed(ManyTracks) {
    _ = opts;

    const url = try std.fmt.allocPrint(
        alloc,
        urls.base_url ++ "/artists/{s}/top-tracks",
        .{artist_id},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    std.debug.print("{s}\n", .{body});

    return try std.json.parseFromSlice(
        ManyTracks,
        alloc,
        body,
        .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        },
    );
}

// Deprecated
// pub fn getRelated(
//     alloc: std.mem.Allocator,
//     client: anytype,
//     artist_id: types.SpotifyId,
//     opts: struct {},
// ) !std.json.Parsed(ManyArtists) {
//     _ = opts;

//     const url = try std.fmt.allocPrint(
//         alloc,
//         urls.base_url ++ "/artists/{s}/related-artists",
//         .{artist_id},
//     );
//     defer alloc.free(url);

//     const body = try client.get(
//         alloc,
//         try std.Uri.parse(url),
//     );
//     defer alloc.free(body);

//     return try std.json.parseFromSlice(
//         ManyArtists,
//         alloc,
//         body,
//         .{
//             .ignore_unknown_fields = true,
//             .allocate = .alloc_always,
//         },
//     );
// }
