// Don't think I need this...
// I can just use the normal http client and
// then authenticate the request directly
const std = @import("std");

pub fn Client(comptime T: type) type {
    return struct {
        const Self = @This();

        authenticator: T,
        allocator: std.mem.Allocator,
        client: std.http.Client = undefined,
        header_buffer: [1024]u8 = undefined,

        pub const Options = struct {
            authenticator: T,
            allocator: std.mem.Allocator,
        };

        pub fn init(opts: Options) Self {
            return .{
                .authenticator = opts.authenticator,
                .allocator = opts.allocator,
                .client = .{
                    .allocator = opts.allocator,
                },
            };
        }

        pub fn deinit(self: Self) void {
            var client = self.client;
            client.deinit();
        }
    };
}
