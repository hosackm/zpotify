const std = @import("std");
const zp = @import("zpotify");

test "parse album" {
    const alloc = std.testing.allocator;
    const data = @import("./data/files.zig").find_album;

    const album = try std.json.parseFromSlice(
        zp.Album,
        alloc,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer album.deinit();
}

test "parse new releases" {
    const alloc = std.testing.allocator;
    const data = @import("./data/files.zig").new_releases;

    const new_releases = try std.json.parseFromSlice(
        zp.Album.PagedSimpleAlbum,
        alloc,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer new_releases.deinit();
}

// ---------
// album.zig
// ---------
test "parse user's albums" {
    const alloc = std.testing.allocator;
    const data = @import("./data/files.zig").current_users_albums;

    const albums = try std.json.parseFromSlice(
        zp.Paginated(zp.Album.Saved),
        alloc,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer albums.deinit();
}

test "find tracks for album" {
    const alloc = std.testing.allocator;
    const data = @import("./data/files.zig").find_album_tracks;

    const albums = try std.json.parseFromSlice(
        zp.Paginated(zp.Track.Simple),
        alloc,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer albums.deinit();
}

test "parse albums" {
    const alloc = std.testing.allocator;
    const data = @import("./data/files.zig").find_albums;

    const albums = try std.json.parseFromSlice(
        zp.Manyify(zp.Album, "albums"),
        alloc,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer albums.deinit();
}

// ----------
// artist.zig
// ----------
test "parse artist" {
    const files = @import("./data/files.zig");
    const alloc = std.testing.allocator;

    const artist = try std.json.parseFromSlice(
        zp.Artist,
        alloc,
        files.find_artist,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer artist.deinit();
}

test "parse artist top tracks" {
    const files = @import("./data/files.zig");
    const alloc = std.testing.allocator;

    const TopTracks = zp.Manyify(zp.Track.Simple, "tracks");

    const top_tracks = try std.json.parseFromSlice(
        TopTracks,
        alloc,
        files.artist_top_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer top_tracks.deinit();
}

// -------------
// audiobook.zig
// -------------
test "parse audiobook" {
    const audiobook = try std.json.parseFromSlice(
        zp.Audiobook,
        std.testing.allocator,
        @import("./data/files.zig").find_audiobook,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer audiobook.deinit();
}

test "parse audiobooks" {
    const audiobook = try std.json.parseFromSlice(
        zp.Manyify(zp.Audiobook, "audiobooks"),
        std.testing.allocator,
        @import("./data/files.zig").find_audiobooks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer audiobook.deinit();
}

test "parse audiobook chapters" {
    const audiobook = try std.json.parseFromSlice(
        zp.Paginated(zp.Chapter),
        std.testing.allocator,
        @import("./data/files.zig").find_audiobook_chapters,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer audiobook.deinit();
}

test "parse current user's audiobooks" {
    const audiobook = try std.json.parseFromSlice(
        zp.Paginated(zp.Audiobook.Simple),
        std.testing.allocator,
        @import("./data/files.zig").current_users_audiobooks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer audiobook.deinit();
}

// -----------
// category.zig
// -----------
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
        zp.Category,
        std.testing.allocator,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer categories.deinit();
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
        zp.Categories,
        std.testing.allocator,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer categories.deinit();
}

// -----------
// chapter.zig
// -----------
test "parse chapter" {
    const chapter = try std.json.parseFromSlice(
        zp.Chapter,
        std.testing.allocator,
        @import("./data/files.zig").get_chapter,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer chapter.deinit();
}

test "parse chapters" {
    const chapters = try std.json.parseFromSlice(
        zp.Manyify(zp.Chapter, "chapters"),
        std.testing.allocator,
        @import("./data/files.zig").get_chapters,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer chapters.deinit();
}

// -----------
// episode.zig
// -----------
test "parse episode" {
    const episode = try std.json.parseFromSlice(
        zp.Episode,
        std.testing.allocator,
        @import("./data/files.zig").get_episode,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer episode.deinit();
}

test "parse episodes" {
    const episodes = try std.json.parseFromSlice(
        zp.Manyify(zp.Episode, "episodes"),
        std.testing.allocator,
        @import("./data/files.zig").get_episodes,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer episodes.deinit();
}

test "parse saved episodes" {
    const episodes = try std.json.parseFromSlice(
        zp.Paginated(zp.Episode.Saved),
        std.testing.allocator,
        @import("./data/files.zig").current_users_episodes,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer episodes.deinit();
}

// ----------
// search.zig
// ----------
test "parse search result" {
    const artist = try std.json.parseFromSlice(
        zp.Search.Result,
        std.testing.allocator,
        @import("./data/files.zig").search_artist,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer artist.deinit();

    const tracks = try std.json.parseFromSlice(
        zp.Search.Result,
        std.testing.allocator,
        @import("./data/files.zig").search_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();

    //     // Currently don't handle multiple search types
    //     // const track_playlist = try std.json.parseFromSlice(
    //     //     Result,
    //     //     std.testing.allocator,
    //     //     @import("./data/files.zig").search_trackplaylist,
    //     //     .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    //     // );
    //     // defer track_playlist.deinit();
}

// --------
// show.zig
// --------
test "parse show" {
    const show = try std.json.parseFromSlice(
        zp.Show,
        std.testing.allocator,
        @import("./data/files.zig").get_show,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer show.deinit();
}

test "parse show episodes" {
    const episodes = try std.json.parseFromSlice(
        zp.Paginated(zp.Episode.Simple),
        std.testing.allocator,
        @import("./data/files.zig").get_show_episodes,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer episodes.deinit();
}

// ---------
// track.zig
// ---------
test "parse track" {
    const track = try std.json.parseFromSlice(
        zp.Track,
        std.testing.allocator,
        @import("./data/files.zig").find_track,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer track.deinit();
}

test "parse tracks" {
    const tracks = try std.json.parseFromSlice(
        zp.Manyify(zp.Track.Simple, "tracks"),
        std.testing.allocator,
        @import("./data/files.zig").find_tracks_simple,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}

test "parse user's tracks" {
    const tracks = try std.json.parseFromSlice(
        zp.Paginated(zp.Track.Saved),
        std.testing.allocator,
        @import("./data/files.zig").current_users_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}

// ----------
// player.zig
// ----------
test "parse player devices" {
    const devices = try std.json.parseFromSlice(
        zp.Manyify(zp.Player.Device, "devices"),
        std.testing.allocator,
        @import("./data/files.zig").player_available_devices,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer devices.deinit();
}

test "parse player state" {
    const state = try std.json.parseFromSlice(
        zp.Player,
        std.testing.allocator,
        @import("./data/files.zig").player_state,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer state.deinit();
}

// ------------
// playlist.zig
// ------------
test "parse playlist" {
    const playlist = try std.json.parseFromSlice(
        zp.Playlist,
        std.testing.allocator,
        @import("./data/files.zig").get_playlist,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer playlist.deinit();
}

test "parse playlist tracks" {
    const tracks = try std.json.parseFromSlice(
        zp.Paginated(zp.Playlist.PlaylistTrack),
        std.testing.allocator,
        @import("./data/files.zig").playlist_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}

test "get user playlists" {
    const playlists = try std.json.parseFromSlice(
        zp.Paginated(zp.Playlist),
        std.testing.allocator,
        @import("./data/files.zig").current_users_playlists,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer playlists.deinit();
}

// --------
// user.zig
// --------
test "parse user's top artists" {
    const artists = try std.json.parseFromSlice(
        zp.Paginated(zp.Artist),
        std.testing.allocator,
        @import("./data/files.zig").current_users_top_artists,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer artists.deinit();
}

test "parse user's top tracks" {
    const tracks = try std.json.parseFromSlice(
        zp.Paginated(zp.Track.Simple),
        std.testing.allocator,
        @import("./data/files.zig").current_users_top_tracks,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}

test "parse user" {
    const data =
        \\{
        \\"country": "string",
        \\"display_name": "string",
        \\"email": "string",
        \\"explicit_content": {
        \\  "filter_enabled": false,
        \\  "filter_locked": false
        \\},
        \\"external_urls": {
        \\  "spotify": "string"
        \\},
        \\"followers": {
        \\  "href": "string",
        \\  "total": 0
        \\},
        \\"href": "string",
        \\"id": "string",
        \\"images": [
        \\  {
        \\    "url": "https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228",
        \\    "height": 300,
        \\    "width": 300
        \\  }
        \\],
        \\"product": "string",
        \\"type": "string",
        \\"uri": "string"
        \\}
    ;
    const user = try std.json.parseFromSlice(
        zp.User,
        std.testing.allocator,
        data,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer user.deinit();
}

test "parse user's followed artists" {
    const tracks = try std.json.parseFromSlice(
        zp.User.CursoredArtists,
        std.testing.allocator,
        @import("./data/files.zig").current_users_followed_artists,
        .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
    );
    defer tracks.deinit();
}
