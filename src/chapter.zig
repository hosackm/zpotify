//! Chapters from the web API reference
const std = @import("std");
const types = @import("types.zig");
const Image = @import("image.zig");
const base_url = @import("url.zig").base_url;

const Self = @This();

pub const ResumePoint = struct {
    fully_played: bool,
    resume_position_ms: usize,
};

// Can probably remove simplified because it contains all fields
pub const Simplified = struct {
    available_markets: []const []const u8,
    chapter_number: usize,
    description: []const u8,
    html_description: []const u8,
    duration_ms: usize,
    explicit: bool,
    external_urls: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    images: []const Image,
    languages: []const []const u8,
    name: []const u8,
    release_date: []const u8,
    release_date_precision: []const u8,
    type: []const u8,
    uri: types.SpotifyUri,

    // missing if you haven't played yet?
    // resume_point: ResumePoint,
    // is_playable: bool,

    // missing
    // restrictions: std.json.Value,
};

pub usingnamespace Simplified;

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !std.json.Parsed(Simplified) {
    _ = opts;
    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/chapters/{s}",
        .{id},
    );
    defer alloc.free(url);

    const body = try client.get(alloc, try std.Uri.parse(url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Simplified,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const Many = struct { chapters: []const Simplified };
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
        base_url ++ "/chapters?ids={s}",
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
