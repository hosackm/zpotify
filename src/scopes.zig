const std = @import("std");
// ScopeImageUpload seeks permission to upload images to Spotify on your behalf.
pub const ScopeImageUpload = "ugc-image-upload";
// ScopePlaylistReadPrivate seeks permission to read
// a user's private playlists.
pub const ScopePlaylistReadPrivate = "playlist-read-private";
// ScopePlaylistModifyPublic seeks write access
// to a user's public playlists.
pub const ScopePlaylistModifyPublic = "playlist-modify-public";
// ScopePlaylistModifyPrivate seeks write access to
// a user's private playlists.
pub const ScopePlaylistModifyPrivate = "playlist-modify-private";
// ScopePlaylistReadCollaborative seeks permission to
// access a user's collaborative playlists.
pub const ScopePlaylistReadCollaborative = "playlist-read-collaborative";
// ScopeUserFollowModify seeks write/delete access to
// the list of artists and other users that a user follows.
pub const ScopeUserFollowModify = "user-follow-modify";
// ScopeUserFollowRead seeks read access to the list of
// artists and other users that a user follows.
pub const ScopeUserFollowRead = "user-follow-read";
// ScopeUserLibraryModify seeks write/delete access to a
// user's "Your Music" library.
pub const ScopeUserLibraryModify = "user-library-modify";
// ScopeUserLibraryRead seeks read access to a user's "Your Music" library.
pub const ScopeUserLibraryRead = "user-library-read";
// ScopeUserReadPrivate seeks read access to a user's
// subscription details (type of user account).
pub const ScopeUserReadPrivate = "user-read-private";
// ScopeUserReadEmail seeks read access to a user's email address.
pub const ScopeUserReadEmail = "user-read-email";
// ScopeUserReadCurrentlyPlaying seeks read access to a user's currently playing track
pub const ScopeUserReadCurrentlyPlaying = "user-read-currently-playing";
// ScopeUserReadPlaybackState seeks read access to the user's current playback state
pub const ScopeUserReadPlaybackState = "user-read-playback-state";
// ScopeUserModifyPlaybackState seeks write access to the user's current playback state
pub const ScopeUserModifyPlaybackState = "user-modify-playback-state";
// ScopeUserReadRecentlyPlayed allows access to a user's recently-played songs
pub const ScopeUserReadRecentlyPlayed = "user-read-recently-played";
// ScopeUserTopRead seeks read access to a user's top tracks and artists
pub const ScopeUserTopRead = "user-top-read";
// ScopeStreaming seeks permission to play music and control playback on your other devices.
pub const ScopeStreaming = "streaming";

pub const AllScopes = ScopeImageUpload ++ "%20" ++ ScopePlaylistReadPrivate ++ "%20" ++ ScopePlaylistModifyPublic ++ "%20" ++ ScopePlaylistModifyPrivate ++ "%20" ++ ScopePlaylistReadCollaborative ++ "%20" ++ ScopeUserFollowModify ++ "%20" ++ ScopeUserFollowRead ++ "%20" ++ ScopeUserLibraryModify ++ "%20" ++ ScopeUserLibraryRead ++ "%20" ++ ScopeUserReadPrivate ++ "%20" ++ ScopeUserReadEmail ++ "%20" ++ ScopeUserReadCurrentlyPlaying ++ "%20" ++ ScopeUserReadPlaybackState ++ "%20" ++ ScopeUserModifyPlaybackState ++ "%20" ++ ScopeUserReadRecentlyPlayed ++ "%20" ++ ScopeUserTopRead ++ "%20" ++ ScopeStreaming;
