//! Shows from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Episode = @import("episode.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;

const Self = @This();

pub usingnamespace Simplified;

pub const Simplified = struct {
    available_markets: []const []const u8,
    copyrights: []const struct { text: []const u8, type: []const u8 },
    description: []const u8,
    html_description: []const u8,
    explicit: bool,
    external_urls: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    images: []const Image,
    is_externally_hosted: bool,
    languages: []const []const u8,
    media_type: []const u8,
    name: []const u8,
    publisher: []const u8,
    type: []const u8,
    uri: types.SpotifyUri,
    total_episodes: usize,
};

// extended
// url: []const u8,  // missing in simplified

// Spotify API often returns null instead of episode objects.
episodes: Paged(?Episode.Simplified),

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(Self) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(M(Simplified, "shows")) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        M(Simplified, "shows"),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getEpisodes(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !P(Paged(?Episode.Simplified)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows/{s}/episodes",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    std.debug.print("{s}\n", .{body});

    return try std.json.parseFromSlice(
        Paged(?Episode.Simplified),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub const Saved = struct { added_at: []const u8, show: Simplified };
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !P(Paged(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/shows",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    std.debug.print("{s}\n", .{body});

    return try std.json.parseFromSlice(
        Paged(Saved),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn save(
    alloc: std.mem.Allocator,
    client: anytype,
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
    const body = try client.put(alloc, try std.Uri.parse(show_url), .{});
    defer alloc.free(body);
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
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
    const body = try client.delete(alloc, try std.Uri.parse(show_url), .{});
    defer alloc.free(body);
}

pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !P([]bool) {
    const show_url = try url.build(
        alloc,
        url.base_url,
        "/me/shows/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    const body = try client.get(alloc, try std.Uri.parse(show_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
