//! Search from the web API reference
const std = @import("std");
const url = @import("url.zig");
const P = std.json.Parsed;

const Result = union(enum) {
    tracks: std.json.Value,
    artists: std.json.Value,
    albums: std.json.Value,
    playlists: std.json.Value,
    shows: std.json.Value,
    episodes: std.json.Value,
    audiobooks: std.json.Value,

    pub fn jsonParse(
        alloc: std.mem.Allocator,
        s: anytype,
        opts: std.json.ParseOptions,
    ) !Result {
        const parsed = try std.json.parseFromSlice(
            std.json.Value,
            alloc,
            s.input,
            opts,
        );
        defer parsed.deinit();

        // don't need to scan input
        while (try s.next() != .end_of_document) {}

        var iter = parsed.value.object.iterator();
        const entry = iter.next().?;
        if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "tracks",
        )) {
            return .{
                .tracks = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "artists",
        )) {
            return .{
                .artists = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "albums",
        )) {
            return .{
                .albums = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "playlists",
        )) {
            return .{
                .playlists = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "episodes",
        )) {
            return .{
                .episodes = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "shows",
        )) {
            return .{
                .shows = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else if (std.mem.eql(
            u8,
            entry.key_ptr.*,
            "audiobooks",
        )) {
            return .{
                .audiobooks = (try std.json.parseFromSlice(
                    std.json.Value,
                    alloc,
                    s.input,
                    opts,
                )).value,
            };
        } else unreachable;
    }
};

// this needs to be a union

const Self = @This();

pub fn search(
    alloc: std.mem.Allocator,
    client: anytype,
    query: []const u8,
    search_type: enum {
        album,
        artist,
        playlist,
        track,
        show,
        episode,
        audiobook,
    },
    opts: struct {
        market: ?[]const u8 = null,
        limit: ?usize = null,
        offset: ?usize = null,
        include_external: ?[]const u8 = null,
    },
) !P(Result) {
    const search_url = try url.build(
        alloc,
        url.base_url,
        "/search",
        null,
        .{
            .q = @as(?[]const u8, query),
            .type = @as(?[]const u8, @tagName(search_type)),
            .market = opts.market,
            .limit = opts.limit,
            .offset = opts.offset,
            .include_external = opts.include_external,
        },
    );
    defer alloc.free(search_url);

    const body = try client.get(alloc, try std.Uri.parse(search_url));
    defer alloc.free(body);

    return try std.json.parseFromSlice(
        Result,
        alloc,
        body,
        .{
            .allocate = .alloc_always,
            .ignore_unknown_fields = true,
        },
    );
}
