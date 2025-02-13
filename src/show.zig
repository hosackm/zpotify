//! Shows from the web API reference
const std = @import("std");
const types = @import("types.zig");
const url = @import("url.zig");
const Image = @import("image.zig");
const Episode = @import("episode.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;
const JsonResponse = types.JsonResponse;

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

url: ?[]const u8 = null,
episodes: Paged(?Episode.Simplified),

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows/{s}",
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
) !JsonResponse(M(Simplified, "shows")) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(M(Simplified, "shows")).parse(alloc, &request);
}

pub fn getEpisodes(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(?Episode.Simplified)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/shows/{s}/episodes",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(Paged(?Episode.Simplified)).parse(alloc, &request);
}

pub const Saved = struct { added_at: []const u8, show: Simplified };
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/shows",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
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
        "/me/shows",
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
        "/me/shows",
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
        "/me/shows/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(show_url);

    var request = try client.get(alloc, try std.Uri.parse(show_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}

test "parse show" {
    const show = try std.json.parseFromSlice(
        Self,
        std.testing.allocator,
        @import("test_data/files.zig").get_show,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer show.deinit();
}

test "parse show episodes" {
    const episodes = try std.json.parseFromSlice(
        Self,
        std.testing.allocator,
        @import("test_data/files.zig").get_show_episodes,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer episodes.deinit();
}
