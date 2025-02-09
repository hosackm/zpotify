//! Categories from the web API reference
//! https://developer.spotify.com/documentation/web-api/reference/get-categories
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Paged = types.Paginated;
const P = std.json.Parsed;
const M = types.Manyify;

href: []const u8,
id: types.SpotifyCategoryId,
name: []const u8,
icons: []const Image,

const Self = @This();

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct {
        locale: ?[]const u8 = null,
        limit: ?u16 = null,
        offset: ?u16 = null,
    },
) !P(Self) {
    const category_url = try url.build(
        alloc,
        url.base_url,
        "/browse/categories/{s}",
        id,
        .{
            .locale = opts.locale,
            .limit = opts.limit,
            .offset = opts.offset,
        },
    );
    defer alloc.free(category_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(category_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

// Yet a third way to return a grouping of objects...
const Categories = struct { categories: Paged(Self) };
pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        locale: ?[]const u8 = null,
        limit: ?u16 = null,
        offset: ?u16 = null,
    },
) !P(Categories) {
    const category_url = try url.build(
        alloc,
        url.base_url,
        "/browse/categories",
        null,
        .{
            .locale = opts.locale,
            .limit = opts.limit,
            .offset = opts.offset,
        },
    );
    defer alloc.free(category_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(category_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Categories,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
