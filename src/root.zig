pub usingnamespace @import("auth.zig");
pub usingnamespace @import("scopes.zig");
pub usingnamespace @import("urls.zig");

// Spotify API Reference Stuff
pub usingnamespace @import("categories.zig");
pub usingnamespace @import("player.zig");
pub usingnamespace @import("playlists.zig");
pub usingnamespace @import("search.zig");
pub usingnamespace @import("error.zig");
pub usingnamespace @import("types.zig");

pub const Client = @import("client.zig").Client;
pub const Artist = @import("artist.zig");
pub const Album = @import("album.zig");
pub const Track = @import("track.zig");
pub const User = @import("user.zig");
pub const Audiobook = @import("audiobook.zig");
pub const Chapter = @import("chapter.zig");
pub const Episode = @import("episode.zig");
pub const Show = @import("show.zig");
pub const Genre = @import("genre.zig");
pub const Markets = @import("markets.zig");
