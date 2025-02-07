//! Audiobooks from the web API reference
const std = @import("std");
const types = @import("types.zig");
const Image = @import("image.zig");
const Chapter = @import("chapter.zig");
const url = @import("url.zig");

const Paged = types.Paginated;
const M = types.Manyify;
const P = std.json.Parsed;

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
chapters: Paged(Chapter.Simplified),

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(Self) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(audiobook_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(audiobook_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getMany(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !P(M(Self, "audiobooks")) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(audiobook_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(audiobook_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        M(Self, "audiobooks"),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getChapters(
    alloc: std.mem.Allocator,
    client: anytype,
    comptime id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u16 = null },
) !P(Paged(Chapter.Simplified)) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/audiobooks/{s}/chapters",
        id,
        .{ .market = opts.market, .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(audiobook_url);

    const body = try client.get(
        alloc,
        try std.Uri.parse(audiobook_url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(Chapter.Simplified),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u16 = null },
) !P(Paged(Simplified)) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks",
        null,
        .{ .limit = opts.limit, .offset = opts.offset },
    );
    defer alloc.free(audiobook_url);
    const body = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Paged(Simplified),
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
    // const joined = try std.mem.join(alloc, "%2C", ids);
    // defer alloc.free(joined);

    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(audiobook_url);
    _ = try client.put(alloc, try std.Uri.parse(audiobook_url), .{});
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

    _ = try client.delete(alloc, try std.Uri.parse(audiobook_url), .{});
}

pub fn areSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !P([]bool) {
    const audiobook_url = try url.build(
        alloc,
        url.base_url,
        "/me/audiobooks/contains",
        null,
        .{ .ids = ids },
    );
    defer alloc.free(audiobook_url);

    const body = try client.get(alloc, try std.Uri.parse(audiobook_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        []bool,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}
