//! Search from the web API reference
const std = @import("std");
const url = @import("url.zig");
const P = std.json.Parsed;
const JsonResponse = @import("types.zig").JsonResponse;

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

pub const Type = enum {
    album,
    artist,
    playlist,
    track,
    show,
    episode,
    audiobook,
};

const Self = @This();

pub fn search(
    alloc: std.mem.Allocator,
    client: anytype,
    query: []const u8,
    search_type: Type,
    opts: struct {
        market: ?[]const u8 = null,
        limit: ?usize = null,
        offset: ?usize = null,
        include_external: ?[]const u8 = null,
    },
) !JsonResponse(Result) {
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

    var request = try client.get(alloc, try std.Uri.parse(search_url));
    defer request.deinit();
    return JsonResponse(Result).parse(alloc, &request);
}

test "parse search result" {
    const artist = try std.json.parseFromSlice(
        Result,
        std.testing.allocator,
        @import("test_data/files.zig").search_artist,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer artist.deinit();

    const tracks = try std.json.parseFromSlice(
        Result,
        std.testing.allocator,
        @import("test_data/files.zig").search_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();

    // Currently don't handle multiple search types
    // const track_playlist = try std.json.parseFromSlice(
    //     Result,
    //     std.testing.allocator,
    //     @import("test_data/files.zig").search_trackplaylist,
    //     .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    // );
    // defer track_playlist.deinit();
}
