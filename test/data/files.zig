//! Test data files from github.com/zmb3/spotify
const std = @import("std");

pub const artist_top_tracks = @embedFile("./artist_top_tracks.txt");
pub const current_users_albums = @embedFile("./current_users_albums.txt");
pub const current_users_audiobooks = @embedFile("./current_users_audiobooks.txt");
pub const current_users_episodes = @embedFile("./current_users_episodes.txt");
pub const current_users_followed_artists = @embedFile("./current_users_followed_artists.txt");
pub const current_users_playlists = @embedFile("./current_users_playlists.txt");
pub const current_users_top_artists = @embedFile("./current_users_top_artists.txt");
pub const current_users_top_tracks = @embedFile("./current_users_top_tracks.txt");
pub const current_users_tracks = @embedFile("./current_users_tracks.txt");
pub const featured_playlists = @embedFile("./featured_playlists.txt");
pub const find_album = @embedFile("./find_album.txt");
pub const find_album_tracks = @embedFile("./find_album_tracks.txt");
pub const find_albums = @embedFile("./find_albums.txt");
pub const find_artist = @embedFile("./find_artist.txt");
pub const find_audiobook = @embedFile("./find_audiobook.txt");
pub const find_audiobook_chapters = @embedFile("./find_audiobook_chapters.txt");
pub const find_audiobooks = @embedFile("./find_audiobooks.txt");
pub const find_track = @embedFile("./find_track.txt");
pub const find_track_with_floats = @embedFile("./find_track_with_floats.txt");
pub const find_tracks_notfound = @embedFile("./find_tracks_notfound.txt");
pub const find_tracks_simple = @embedFile("./find_tracks_simple.txt");
pub const get_audio_analysis = @embedFile("./get_audio_analysis.txt");
pub const get_chapter = @embedFile("./get_chapter.txt");
pub const get_chapters = @embedFile("./get_chapters.txt");
pub const get_episode = @embedFile("./get_episode.txt");
pub const get_episodes = @embedFile("./get_episodes.txt");
pub const get_playlist = @embedFile("./get_playlist.txt");
pub const get_playlist_episodes = @embedFile("./get_playlist_episodes.txt");
pub const get_playlist_mixed = @embedFile("./get_playlist_with_tracks_and_episodes.txt");
pub const get_playlist_opt = @embedFile("./get_playlist_opt.txt");
pub const get_queue = @embedFile("./get_queue.txt");
pub const get_show = @embedFile("./get_show.txt");
pub const get_show_episodes = @embedFile("./get_show_episodes.txt");
pub const new_releases = @embedFile("./new_releases.txt");
pub const player_available_devices = @embedFile("./player_available_devices.txt");
pub const player_currently_playing = @embedFile("./player_currently_playing.txt");
pub const player_recently_played = @embedFile("./player_recently_played.txt");
pub const player_state = @embedFile("./player_state.txt");
pub const playlist_items_episodes = @embedFile("./playlist_items_episodes.json");
pub const playlist_items_episodes_and_tracks = @embedFile("./playlist_items_episodes_and_tracks.json");
pub const playlist_items_tracks = @embedFile("./playlist_items_tracks.json");
pub const playlist_tracks = @embedFile("./playlist_tracks.txt");
pub const playlists_for_user = @embedFile("./playlists_for_user.txt");
pub const recommendations = @embedFile("./recommendations.txt");
pub const related_artists = @embedFile("./related_artists.txt");
pub const related_artists_with_floats = @embedFile("./related_artists_with_floats.txt");
pub const search_artist = @embedFile("./search_artist.txt");
pub const search_trackplaylist = @embedFile("./search_trackplaylist.txt");
pub const search_tracks = @embedFile("./search_tracks.txt");
