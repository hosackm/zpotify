//! Episodes from the web API reference
const std = @import("std");
const types = @import("types.zig");
const Show = @import("show.zig");
const Image = @import("image.zig");
// const base_url = @import("url.zig").base_url;
const url = @import("url.zig");

description: []const u8,
html_description: []const u8,
duration_ms: usize,
explicit: bool,
external_urls: std.json.Value,
href: []const u8,
id: types.SpotifyId,
images: []const Image,
is_externally_hosted: bool,
language: []const u8,
languages: []const []const u8,
name: []const u8,
release_date: []const u8,
release_date_precision: []const u8,
type: []const u8,
uri: types.SpotifyUri,
show: Show,

// missing
// is_playable: bool,
// resume_point
// restrictions

const Self = @This();

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !std.json.Parsed(Self) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/episodes/{s}",
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

const Many = struct { episodes: []const Self };
pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !std.json.Parsed(Many) {
    _ = opts;
    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/episodes",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Many,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const Saved = struct { added_at: []const u8, episode: Self };
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !std.json.Parsed(types.Paginated(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/episodes",
        null,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        types.Paginated(Saved),
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
    const data: struct { ids: []const types.SpotifyId } = .{ .ids = ids };
    const body = try client.put(alloc, try std.Uri.parse(url.base_url ++ "/me/episodes"), data);
    defer alloc.free(body);
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const data: struct { ids: []const types.SpotifyId } = .{ .ids = ids };
    const body = try client.delete(alloc, try std.Uri.parse(url.base_url ++ "/me/episodes"), data);
    defer alloc.free(body);
}

pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !std.json.Parsed([]bool) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/episodes/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(ep_url);

    const body = try client.get(alloc, try std.Uri.parse(ep_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
