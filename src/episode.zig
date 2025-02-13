//! Episodes from the web API reference
const std = @import("std");
const types = @import("types.zig");
const Show = @import("show.zig");
const Image = @import("image.zig");
const url = @import("url.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;
const JsonResponse = types.JsonResponse;

const Self = @This();

pub const Simplified = struct {
    audio_preview_url: []const u8,
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
    is_playable: ?bool = null,
    resume_point: ?types.ResumePoint = null,
    restrictions: ?std.json.Value = null,
};
pub usingnamespace Simplified;

show: Show.Simplified,

// Retrieve one Episode by SpotifyId
pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/episodes/{s}",
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
) !JsonResponse(M(Self, "episodes")) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/episodes",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse(M(Self, "episodes")).parse(alloc, &request);
}

pub const Saved = struct { added_at: []const u8, episode: Self };
pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u8 = null },
) !JsonResponse(Paged(Saved)) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/episodes",
        null,
        .{
            .market = opts.market,
            .limit = opts.limit,
            .offset = opts.offset,
        },
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
    const data: struct { ids: []const types.SpotifyId } = .{ .ids = ids };
    var request = try client.put(alloc, try std.Uri.parse(url.base_url ++ "/me/episodes"), data);
    defer request.deinit();
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const data: struct { ids: []const types.SpotifyId } = .{ .ids = ids };
    var request = try client.delete(alloc, try std.Uri.parse(url.base_url ++ "/me/episodes"), data);
    defer request.deinit();
}

pub fn contains(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const ep_url = try url.build(
        alloc,
        url.base_url,
        "/me/episodes/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(ep_url);

    var request = try client.get(alloc, try std.Uri.parse(ep_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}
