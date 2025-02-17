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
    expires_in: u64, // seconds, (always 3600 seconds or 1 hour)
    refresh_token: []const u8,
};

pub fn Authenticator(comptime T: type) type {
    std.debug.assert(@hasDecl(T, "get"));
    std.debug.assert(
        @TypeOf(@field(T, "get")) == fn (T, Credentials) T.Error![]const u8,
    );

    return struct {
        const Self = @This();

        pub const Options = struct {
            token_source: T,
            credentials: Credentials,
            allocator: std.mem.Allocator,
        };

        token_source: T,
        credentials: Credentials,
        allocator: std.mem.Allocator,
        buffer: [384]u8 = undefined,

        pub fn init(opts: Options) Self {
            return .{
                .token_source = opts.token_source,
                .credentials = opts.credentials,
                .allocator = opts.allocator,
            };
        }

        const Request = std.http.Client.Request;
        pub fn authenticate(self: *Self, req: *Request) !void {
            const access_token = try self.*.token_source.get(self.credentials);
            defer self.*.token_source.allocator.free(access_token);
            _ = std.mem.replace(
                u8,
                "Bearer {s}",
                "{s}",
                access_token,
                &self.*.buffer,
            );

            // sign the header
            const len: usize = access_token.len + 7;
            req.*.headers.authorization = .{ .override = self.*.buffer[0..len] };
        }
    };
}
