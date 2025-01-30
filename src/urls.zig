const std = @import("std");

pub const base_url = "https://api.spotify.com/v1/";
pub const auth_url = "https://accounts.spotify.com/authorize";
pub const token_url = "https://accounts.spotify.com/api/token";
pub const base_uri = std.Uri.parse(base_url[0..]) catch unreachable;
pub const auth_uri = std.Uri.parse(auth_url[0..]) catch unreachable;
pub const token_uri = std.Uri.parse(token_url[0..]) catch unreachable;
