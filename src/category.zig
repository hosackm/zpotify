//! Categories from the web API reference
//! https://developer.spotify.com/documentation/web-api/reference/get-categories
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Paged = types.Paginated;
const P = std.json.Parsed;
const M = types.Manyify;
const JsonResponse = types.JsonResponse;

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

test "parse category" {
    const data =
        \\{
        \\"href": "string",
        \\"icons": [
        \\    {
        \\    "url": "https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228",
        \\    "height": 300,
        \\    "width": 300
        \\    }
        \\],
        \\"id": "equal",
        \\"name": "EQUAL"
        \\}
    ;
    const categories = try std.json.parseFromSlice(
        Self,
        std.testing.allocator,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer categories.deinit();
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

test "parse categories" {
    const data =
        \\{
        \\    "categories": {
        \\        "href": "https://api.spotify.com/v1/me/shows?offset=0&limit=20",
        \\        "limit": 20,
        \\        "next": "https://api.spotify.com/v1/me/shows?offset=1&limit=1",
        \\        "offset": 0,
        \\        "previous": "https://api.spotify.com/v1/me/shows?offset=1&limit=1",
        \\        "total": 4,
        \\        "items": [
        \\        {
        \\            "href": "string",
        \\            "icons": [
        \\            {
        \\                "url": "https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228",
        \\                "height": 300,
        \\                "width": 300
        \\            }
        \\            ],
        \\            "id": "equal",
        \\            "name": "EQUAL"
        \\        }
        \\        ]
        \\    }
        \\}
    ;
    const categories = try std.json.parseFromSlice(
        Categories,
        std.testing.allocator,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer categories.deinit();
}
