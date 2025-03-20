//! This module contains definitions and methods for interacting with
//! Chapter resources (associated with Audiobooks) from the Spotify Web API.
//! Chapters are only available within the US, UK, Canada, Ireland, New Zealand
//! and Australia markets.

const std = @import("std");
const types = @import("types.zig");
const Image = @import("image.zig");
const url = @import("url.zig");
const Client = @import("client.zig").Client;

const Chapter = @This();

// A list of the countries in which the chapter can be played, identified
// by their ISO 3166-1 alpha-2 code
available_markets: []const []const u8,
// The number of the chapter
chapter_number: u16,
// A description of the chapter. HTML tags are stripped away from
// this field, use html_description field in case HTML tags are needed.
description: []const u8,
// A description of the chapter. This field may contain HTML tags.
html_description: []const u8,
// The chapter length in milliseconds.
duration_ms: u32,
// Whether or not the chapter has explicit content
// (true = yes it does; false = no it does not OR unknown).
explicit: bool,
// External URLs for this chapter.
external_urls: std.json.Value,
// A link to the Web API endpoint providing full details of the chapter.
href: []const u8,
// The Spotify ID for the chapter.
id: types.SpotifyId,
// The cover art for the chapter in various sizes, widest first.
images: []const Image,
// A list of the languages used in the chapter, identified by their ISO 639-1 code.
languages: []const []const u8,
// The name of the chapter.
name: []const u8,
// The date the chapter was first released, for example "1981-12-15". Depending on
// the precision, it might be shown as "1981" or "1981-12".
release_date: []const u8,
// The precision with which release_date value is known.
// Allowed values: "year", "month", "day"
release_date_precision: []const u8,
// The object type. Allowed values: "episode"
type: []const u8,
// The Spotify URI for the chapter.
uri: types.SpotifyUri,
// The user's most recent position in the chapter. Set if the supplied access
// token is a user token and has the scope 'user-read-playback-position'.
resume_point: ?types.ResumePoint = null,
// True if the chapter is playable in the given market. Otherwise false.
is_playable: ?bool = null,
// Included in the response when a content restriction is applied.
restrictions: ?std.json.Value = null,

// Get Spotify catalog information for a single audiobook chapter.
// https://developer.spotify.com/documentation/web-api/reference/get-a-chapter
//
// id - Spotify Chapter ID
// opts.market - an optional ISO 3166-1 Country Code
pub fn getOne(
    alloc: std.mem.Allocator,
    client: *Client,
    id: types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !types.JsonResponse(Chapter) {
    const chapter_url = try url.build(
        alloc,
        url.base_url,
        "/chapters/{s}",
        id,
        .{ .market = opts.market },
    );
    defer alloc.free(chapter_url);

    var request = try client.get(alloc, try std.Uri.parse(chapter_url));
    defer request.deinit();
    return types.JsonResponse(Chapter).parseRequest(alloc, &request);
}

const Many = struct { chapters: []const Chapter };

// Get Spotify catalog information for several audiobook chapters identified by
// their Spotify IDs.
// https://developer.spotify.com/documentation/web-api/reference/get-several-chapters
//
// ids - slice of Spotify Chapter IDs
// opts.market - an optional ISO 3166-1 Country Code
pub fn getMany(
    alloc: std.mem.Allocator,
    client: *Client,
    ids: []const types.SpotifyId,
    opts: struct { market: ?[]const u8 = null },
) !types.JsonResponse(Many) {
    const chapter_url = try url.build(
        alloc,
        url.base_url,
        "/chapters",
        null,
        .{ .ids = ids, .market = opts.market },
    );
    defer alloc.free(chapter_url);

    var request = try client.get(alloc, try std.Uri.parse(chapter_url));
    defer request.deinit();
    return types.JsonResponse(Many).parseRequest(alloc, &request);
}
