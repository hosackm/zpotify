//! Audiobooks from the web API reference
const std = @import("std");
const types = @import("types.zig");
const Image = @import("image.zig");
const Chapter = @import("chapter.zig");
const base_url = @import("urls.zig").base_url;

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
chapters: types.Paginated(Chapter.Simplified),

pub fn getOne(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !std.json.Parsed(Self) {
    _ = opts;
    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/audiobooks/{s}",
        .{id},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Self,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

const Many = struct { audiobooks: []const Self };
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
        base_url ++ "/audiobooks?ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Many,
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getChapters(
    alloc: std.mem.Allocator,
    client: anytype,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null, limit: ?u8 = null, offset: ?u16 = null },
) !std.json.Parsed(types.Paginated(Chapter.Simplified)) {
    _ = opts;

    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/audiobooks/{s}/chapters",
        .{id},
    );
    defer alloc.free(url);

    // do something with the opts
    const body = try client.get(
        alloc,
        try std.Uri.parse(url),
    );
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        types.Paginated(Chapter.Simplified),
        alloc,
        body,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    );
}

pub fn getSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    opts: struct { limit: ?u8 = null, offset: ?u16 = null },
) !std.json.Parsed(types.Paginated(Simplified)) {
    _ = opts;
    // do something with the opts
    const body = try client.get(alloc, try std.Uri.parse(base_url ++ "/me/audiobooks"));
    defer alloc.free(body);

    std.debug.print("{s}\n", .{body});

    return try std.json.parseFromSlice(
        types.Paginated(Simplified),
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
    // do something with the opts
    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/me/audiobooks?ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    _ = try client.put(alloc, try std.Uri.parse(url), .{});
}

pub fn remove(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !void {
    // do something with the opts
    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/me/audiobooks?ids={s}",
        .{joined},
    );
    defer alloc.free(url);

    _ = try client.delete(alloc, try std.Uri.parse(url), .{});
}

pub fn areSaved(
    alloc: std.mem.Allocator,
    client: anytype,
    ids: []const types.SpotifyId,
) !std.json.Parsed([]bool) {
    // do something with the opts
    const joined = try std.mem.join(alloc, "%2C", ids);
    defer alloc.free(joined);

    const url = try std.fmt.allocPrint(
        alloc,
        base_url ++ "/me/audiobooks/contains?ids={s}",
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
