//! Categories from the web API reference
//! https://developer.spotify.com/documentation/web-api/reference/get-categories
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");

// A link to the Web API endpoint returning full details of the category.
href: []const u8,
// The Spotify category ID of the category.
id: types.SpotifyCategoryId,
// The name of the category.
name: []const u8,
// The category icon, in various sizes.
icons: []const Image,

const Self = @This();
const Paged = types.Paginated;
const M = types.Manyify;
const JsonResponse = types.JsonResponse;

// Get a single category used to tag items in Spotify (on, for example,
// the Spotify player’s “Browse” tab).
// id - The Spotify category ID for the category.
// opts.locale - The desired language, consisting of an ISO 639-1 language code
//               and an ISO 3166-1 alpha-2 country code, joined by an underscore.
//               for example (spanish mexico): "es_MX"
pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct {
        locale: ?[]const u8 = null,
        limit: ?u16 = null,
        offset: ?u16 = null,
    },
) !JsonResponse(Self) {
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

    var request = try client.get(alloc, try std.Uri.parse(category_url));
    defer request.deinit();
    return JsonResponse(Self).parse(alloc, &request);
}

// Yet a third way to return a grouping of objects...
pub const Categories = struct { categories: Paged(Self) };

// Get a list of categories used to tag items in Spotify
// (on, for example, the Spotify player’s “Browse” tab).
// https://developer.spotify.com/documentation/web-api/reference/get-categories
//
// opts.market - an optional ISO 3166-1 Country Code
// opts.limit - maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50.
// opts.offset - The index of the first item to return. Default: 0.
// opts.locale - The desired language, consisting of an ISO 639-1 language code
//               and an ISO 3166-1 alpha-2 country code, joined by an underscore.
//               for example (spanish mexico): "es_MX"
pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct {
        locale: ?[]const u8 = null,
        limit: ?u16 = null,
        offset: ?u16 = null,
    },
) !JsonResponse(Categories) {
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

    var request = try client.get(alloc, try std.Uri.parse(category_url));
    defer request.deinit();
    return JsonResponse(Categories).parse(alloc, &request);
}
