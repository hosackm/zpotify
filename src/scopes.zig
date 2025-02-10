const std = @import("std");

const Scopes = std.EnumSet(Keys);
pub const Keys = enum(u17) {
    // upload scopes
    image_upload = 1 << 0,

    // playlist scopes
    playlist_read_private = 1 << 1,
    playlist_modify_public = 1 << 2,
    playlist_modify_private = 1 << 3,
    playlist_read_collaborative = 1 << 4,

    // user data scopes
    user_follow_modify = 1 << 5,
    user_follow_read = 1 << 6,
    user_library_modify = 1 << 7,
    user_library_read = 1 << 8,
    user_read_private = 1 << 9,
    user_read_email = 1 << 10,
    user_read_currently_playing = 1 << 11,
    user_read_playback_state = 1 << 12,
    user_modify_playback_state = 1 << 13,
    user_read_recently_played = 1 << 14,
    user_top_read = 1 << 15,

    // streaming scopes
    streaming = 1 << 16,
};

pub const Everything = Scopes.init(.{
    .image_upload = true,
    .playlist_read_private = true,
    .playlist_modify_public = true,
    .playlist_modify_private = true,
    .playlist_read_collaborative = true,
    .user_follow_modify = true,
    .user_follow_read = true,
    .user_library_modify = true,
    .user_library_read = true,
    .user_read_private = true,
    .user_read_email = true,
    .user_read_currently_playing = true,
    .user_read_playback_state = true,
    .user_modify_playback_state = true,
    .user_read_recently_played = true,
    .user_top_read = true,
});

// Joins scopes as strings separated by whitespace.
pub fn toStringAlloc(alloc: std.mem.Allocator, scopes: Scopes) ![]const u8 {
    var list = std.ArrayList(u8).init(alloc);
    defer list.deinit();

    var iter = scopes.iterator();
    while (iter.next()) |tag| {
        if (list.items.len > 0) try list.append(' ');
        try list.appendSlice(
            switch (tag) {
                .image_upload => "ugc-image-upload",
                .playlist_read_private => "playlist-read-private",
                .playlist_modify_public => "playlist-modify-public",
                .playlist_modify_private => "playlist-modify-private",
                .playlist_read_collaborative => "playlist-read-collaborative",
                .user_follow_modify => "user-follow-modify",
                .user_follow_read => "user-follow-read",
                .user_library_modify => "user-library-modify",
                .user_library_read => "user-library-read",
                .user_read_private => "user-read-private",
                .user_read_email => "user-read-email",
                .user_read_currently_playing => "user-read-currently-playing",
                .user_read_playback_state => "user-read-playback-state",
                .user_modify_playback_state => "user-modify-playback-state",
                .user_read_recently_played => "user-read-recently-played",
                .user_top_read => "user-top-read",
                .streaming => "streaming",
            },
        );
    }
    return list.toOwnedSlice();
}

test "can stringify scopes" {
    const expected = "user-follow-modify user-read-email streaming";
    const scopes = Scopes.init(.{
        .user_follow_modify = true,
        .user_read_email = true,
        .streaming = true,
    });
    const scope_string = try toStringAlloc(
        std.testing.allocator,
        scopes,
    );
    defer std.testing.allocator.free(scope_string);
    try std.testing.expectEqualStrings(scope_string, expected);
}
