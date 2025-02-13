//! Audiobooks from the web API reference
const std = @import("std");
const types = @import("types.zig");
const Image = @import("image.zig");
const Chapter = @import("chapter.zig");
const url = @import("url.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;
const JsonResponse = types.JsonResponse;

const Self = @This();

pub const Simplified = struct {
    authors: []const struct { name: []const u8 },
    available_markets: []const []const u8,
    copyrights: []const struct { text: []const u8, type: []const u8 },
    description: []const u8,
    edition: []const u8,
    explicit: bool,
    html_description: []const u8,
    external_urls: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    images: []const Image,
    languages: []const []const u8,
    media_type: []const u8,
    name: []const u8,
    narrators: []const struct { name: []const u8 },
    publisher: []const u8,
    type: []const u8, // "audiobook"
    uri: types.SpotifyUri,
    total_chapters: usize,
};

pub usingnamespace Simplified;
chapters: Paged(Chapter),

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(Self) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse(Self).parse(alloc, &request);
}

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !JsonResponse(M(Self, "audiobooks")) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse(M(Self, "audiobooks")).parse(alloc, &request);
}

pub fn getChapters(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u16 = null },
) !JsonResponse(Paged(Chapter)) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks/{s}/chapters",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse(Paged(Chapter)).parse(alloc, &request);
}

pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u16 = null },
) !JsonResponse(Paged(Simplified)) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse(Paged(Simplified)).parse(alloc, &request);
}

pub fn save(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(audiobook_url);
    var req = try client.put(alloc, try std.Uri.parse(audiobook_url), .{});
    defer req.deinit();
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(audiobook_url);

    var req = try client.delete(alloc, try std.Uri.parse(audiobook_url), .{});
    defer req.deinit();
}

pub fn areSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !JsonResponse([]bool) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(audiobook_url);

    var request = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer request.deinit();
    return JsonResponse([]bool).parse(alloc, &request);
}
