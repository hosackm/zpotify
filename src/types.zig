const std = @import("std");

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example: 6rqhFgbbKwnb9MLmUQDhG6
pub const SpotifyId = []const u8;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example: spotify:track:6rqhFgbbKwnb9MLmUQDhG6
pub const SpotifyUri = []const u8;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example: party
pub const SpotifyCategoryId = []const u8;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example: wizzler
pub const SpotifyUserId = []const u8;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example URL: wizzler
pub const SpotifyUrl = []const u8;

// For when Spotify returns a group of objects using pages for iteration
pub fn Paginated(comptime T: type) type {
    return struct {
        href: []const u8,
        limit: usize,
        next: ?[]const u8,
        offset: usize,
        previous: ?[]const u8,
        total: usize,
        items: []const T,
    };
}

// For when Spotify returns a group of objects using cursors for iteration.
pub fn Cursored(comptime T: type) type {
    return struct {
        href: []const u8,
        limit: usize,
        next: ?[]const u8,
        cursors: std.json.Value,
        total: usize,
        items: []const T,
    };
}

// Copies a dynamic JSON object by using comptime type reflection.
fn deepCopy(comptime T: type, v: std.json.Value) T {
    _ = v;
    return .{};
}
