const std = @import("std");
const zp = @import("zpotify");
const TokenSource = @import("token.zig").TokenSource;

const Auth = zp.Authenticator(TokenSource);
const Client = zp.Client(Auth);

client: Client,
authenticator: *Auth,
allocator: std.mem.Allocator,

const Self = @This();

pub fn init(alloc: std.mem.Allocator) !Self {
    var em = try std.process.getEnvMap(alloc);
    defer em.deinit();

    const auth: *Auth = try alloc.create(Auth);
    auth.* = .{
        .token_source = .{
            .filename = try std.fmt.allocPrint(
                alloc,
                ".token.json",
                .{},
            ),
            .allocator = alloc,
        },
        .credentials = .{
            .redirect_uri = try alloc.dupe(u8, em.get("SPOTIFY_REDIRECT").?),
            .client_id = try alloc.dupe(u8, em.get("SPOTIFY_ID").?),
            .client_secret = try alloc.dupe(u8, em.get("SPOTIFY_SECRET").?),
        },
        .allocator = alloc,
    };

    return .{
        .client = .{ .authenticator = auth },
        .authenticator = auth,
        .allocator = alloc,
    };
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.client.authenticator.*.credentials.redirect_uri);
    self.allocator.free(self.client.authenticator.*.credentials.client_id);
    self.allocator.free(self.client.authenticator.*.credentials.client_secret);
    self.allocator.free(self.client.authenticator.*.token_source.filename);
    self.allocator.destroy(self.authenticator);
}
