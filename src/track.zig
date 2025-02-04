//! Track from the web API reference
const std = @import("std");
const types = @import("types.zig");
const Album = @import("album.zig");
const Artist = @import("artist.zig");

// Extend from Simplified
pub usingnamespace Simplified;

album: Album,
external_ids: std.json.Value,
is_playable: bool,
name: []const u8,
popularity: u8,

pub const Simplified = struct {
    artists: []const Artist.Simplified,
    available_markets: []const []const u8,
    disc_number: usize,
    duration_ms: usize,
    explicit: bool,
    external_urls: std.json.Value,
    href: []const u8,
    id: types.SpotifyId,
    is_local: bool,
    preview_url: ?[]const u8,
    track_number: usize,
    type: []const u8,
    uri: types.SpotifyUri,
};

// missing
// linked_from: std.json.Value,
// restrictions: std.json.Value,
// missing often
// name: []const u8, // missing from albums/{id}/tracks
// popularity: u8,
// external_ids: std.json.Value,
// is_playable: bool,
// linked_from: std.json.Value,
// restrictions: std.json.Value,
