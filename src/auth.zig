const std = @import("std");

pub const Credentials = struct {
    client_id: []const u8,
    client_secret: []const u8,
    redirect_uri: []const u8,
};

pub fn Authenticator(comptime T: type) type {
    std.debug.assert(@hasDecl(T, "get"));
    std.debug.assert(@TypeOf(@field(T, "get")) == fn (T, Credentials) T.Error![]const u8);

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

        bearer: []u8 = "",
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

            // renew Bearer string
            self.*.bearer = try std.fmt.bufPrint(
                &self.*.buffer,
                "Bearer {s}",
                .{access_token},
            );

            // sign the header
            req.*.headers.authorization = .{ .override = self.bearer };
        }
    };
}
