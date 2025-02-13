//! Track from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Album = @import("album.zig");
const Artist = @import("artist.zig");
const Image = @import("image.zig");

const P = std.json.Parsed;
const M = types.Manyify;
const Paged = types.Paginated;
const JsonResponse = types.JsonResponse;

const Self = @This();

// Extend from Simplified
pub usingnamespace Simplified;

pub const Simplified = struct {
    artists: []const Artist.Simplified,
    available_markets: []const []const u8,
    disc_number: usize,
    duration_ms: usize,
    explicit: bool,
    external_urls: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    is_local: bool,
    name: []const u8,
    preview_url: ?[]const u8,
    track_number: usize,
    type: []const u8,
    uri: types.SpotifyUri,
};

album: Album.Simplified,
external_ids: std.json.Value,
popularity: u8,
is_playable: ?bool = null,
linked_from: ?std.json.Value = null,
restrictions: ?std.json.Value = null,

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/tracks/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Self).parse(alloc, &request);
}

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Simplified, "tracks")) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/tracks",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(M(Simplified, "tracks")).parse(alloc, &request);
}

pub const Saved = struct { added_at: []const u8, track: Simplified };
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Paged(Saved)).parse(alloc, &request);
}

pub fn save(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    var request = try client.put(alloc, try std.Uri.parse(show_url), .{});
    defer request.deinit();
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    var request = try client.delete(alloc, try std.Uri.parse(show_url), .{});
    defer request.deinit();
}

pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/tracks/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    var request = try client.get(alloc, try std.Uri.parse(show_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}

test "parse track" {
    const track = try std.json.parseFromSlice(
        Self,
        std.testing.allocator,
        @import("test_data/files.zig").find_track,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer track.deinit();
}

test "parse tracks" {
    const tracks = try std.json.parseFromSlice(
        M(Simplified, "tracks"),
        std.testing.allocator,
        @import("test_data/files.zig").find_tracks_simple,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}

test "parse user's tracks" {
    const tracks = try std.json.parseFromSlice(
        Paged(Saved),
        std.testing.allocator,
        @import("test_data/files.zig").current_users_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}
