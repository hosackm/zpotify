const std = @import("std");

pub const Credentials = struct {
    client_id: []const u8,
    client_secret: []const u8,
    redirect_uri: []const u8,
};

// https://developer.spotify.com/documentation/web-api/tutorials/refreshing-tokens
pub const Token = struct {
    access_token: []const u8,
    token_type: []const u8,
    scope: []const u8,
    // seconds, (always 3600 seconds or 1 hour)
    expires_in: u64,
    // no refresh_token when refreshing, use default.
    refresh_token: []const u8 = "",
    // set to 0 if not present, we will overwrite this
    expiry: i64 = 0,

    // If the token will expire in one minute we should refresh it
    const expire_delta_secs: i64 = std.time.s_per_min;

    // Parse a token from bytes representing a JSON Token object.
    pub fn parse(alloc: std.mem.Allocator, s: []const u8) !Token {
        var token = try std.json.parseFromSliceLeaky(
            Token,
            alloc,
            s,
            .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
        );

        if (token.expiry == 0) token.expiry = std.time.timestamp() + 3600;

        return token;
    }

    pub fn isExpired(self: Token) bool {
        return std.time.timestamp() > (self.expiry - Token.expire_delta_secs);
    }
};

test "token isExpired" {
    const now = std.time.timestamp();
    var token: Token = .{
        .access_token = "",
        .refresh_token = "",
        .scope = "",
        .token_type = "",
        .expires_in = 3600,
        .expiry = now,
    };

    try std.testing.expect(token.isExpired());
    token.expiry += Token.expire_delta_secs * 2;
    try std.testing.expect(token.isExpired() == false);
}
