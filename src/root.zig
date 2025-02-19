// import all these into main namespace
pub usingnamespace @import("oauth.zig");
pub usingnamespace @import("scopes.zig");
pub usingnamespace @import("url.zig");
pub usingnamespace @import("types.zig");

// Spotify API Reference Stuff
pub const Category = @import("category.zig");
pub const Categories = Category.Categories;
pub const Client = @import("client.zig").Client;
pub const Artist = @import("artist.zig");
pub const Album = @import("album.zig");
pub const Track = @import("track.zig");
pub const User = @import("user.zig");
pub const Audiobook = @import("audiobook.zig");
pub const Chapter = @import("chapter.zig");
pub const Episode = @import("episode.zig");
pub const Playlist = @import("playlist.zig");
pub const Player = @import("player.zig");
pub const Search = @import("search.zig");
pub const Show = @import("show.zig");
pub const Markets = @import("markets.zig");

comptime {
    @import("std").testing.refAllDecls(@This());
}
