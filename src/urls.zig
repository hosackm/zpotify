const std = @import("std");

pub const base_url = "https://api.spotify.com/v1";
pub const auth_url = "https://accounts.spotify.com/authorize";
pub const token_url = "https://accounts.spotify.com/api/token";

pub const base_uri = std.Uri.parse(base_url[0..]) catch unreachable;
pub const auth_uri = std.Uri.parse(auth_url[0..]) catch unreachable;
pub const token_uri = std.Uri.parse(token_url[0..]) catch unreachable;

// Encodes a string for inclusion in a URL. Unsupported characters are converted
// to their corresponding ASCII 2 digit hex codes preceded by a %.
fn encode(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
    var list = std.ArrayList(u8).init(alloc);
    const convert: []const u8 = " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{`}~";

    for (s, 0..) |c, n| {
        const slice = s[n .. n + 1];
        if (!std.mem.containsAtLeast(u8, convert, 1, slice)) {
            try list.append(c);
            continue;
        }
        var buf: [3]u8 = undefined;
        for (try std.fmt.bufPrint(&buf, "%{X}", .{c})) |ch| try list.append(ch);
    }

    return list.toOwnedSlice();
}
