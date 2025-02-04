//! Episodes from the web API reference
const std = @import("std");
const base_url = @import("urls.zig").base_url;
const types = @import("types.zig");
const Show = @import("show.zig");
const Image = @import("image.zig");

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
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !std.json.Parsed(Self) {
    _ = opts;
    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/episodes/{s}",
        .{id},
    );
    defer alloc.free(url);

    const body = try client.get(alloc, try std.Uri.parse(url));
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

    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/episodes?ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    const body = try client.get(alloc, try std.Uri.parse(url));
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
    _ = opts;
    const body = try client.get(alloc, try std.Uri.parse(base_url ++ "/me/episodes"));
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
    const body = try client.put(alloc, try std.Uri.parse(base_url ++ "/me/episodes"), data);
    defer alloc.free(body);
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const data: struct { ids: []const types.SpotifyId } = .{ .ids = ids };
    const body = try client.delete(alloc, try std.Uri.parse(base_url ++ "/me/episodes"), data);
    defer alloc.free(body);
}

pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !std.json.Parsed([]bool) {
    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/me/episodes/contains?ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    const body = try client.get(alloc, try std.Uri.parse(url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
