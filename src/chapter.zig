//! Chapters from the web API reference
const std = @import("std");
const types = @import("types.zig");
const Image = @import("image.zig");
const url = @import("url.zig");

const Self = @This();

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
resume_point: ?types.ResumePoint = null,
is_playable: ?bool = null,
restrictions: ?std.json.Value = null,

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !types.JsonResponse(Self) {
    const chapter_url = try url.build(
        alloc,
        url.base_url,
        "/chapters/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(chapter_url);

    var request = try client.get(alloc, try std.Uri.parse(chapter_url));
    defer request.deinit();
    return types.JsonResponse(Self).parse(alloc, &request);
}

test "parse chapter" {
    const artist = try std.json.parseFromSlice(
        Self,
        std.testing.allocator,
        @import("test_data/files.zig").get_chapter,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer artist.deinit();
}

const Many = struct { chapters: []const Self };
pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !types.JsonResponse(Many) {
    const chapter_url = try url.build(
        alloc,
        url.base_url,
        "/chapters",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(chapter_url);

    var request = try client.get(alloc, try std.Uri.parse(chapter_url));
    defer request.deinit();
    return types.JsonResponse(Many).parse(alloc, &request);
}

test "parse chapters" {
    const artist = try std.json.parseFromSlice(
        Many,
        std.testing.allocator,
        @import("test_data/files.zig").get_chapters,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer artist.deinit();
}
