const std = @import("std");
const zp = @import("zpotify");
const FilePersistedToken = @import("token.zig").FilePersistedToken;

const Auth = zp.Authenticator(FilePersistedToken);
const Client = zp.Client(Auth);

client: Client,
authenticator: *Auth,
allocator: std.mem.Allocator,

const Self = @This();

pub fn init(alloc: std.mem.Allocator) !Self {
    var em = try std.process.getEnvMap(alloc);
    defer em.deinit();

    const auth = try alloc.create(Auth);
    auth.* = .{
        .token_source = .{
            .filename = try alloc.dupe(u8, ".token.json"),
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
        .client = Client.init(alloc, auth),
        .authenticator = auth,
        .allocator = alloc,
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.client.authenticator.*.credentials.redirect_uri);
    self.allocator.free(self.client.authenticator.*.credentials.client_id);
    self.allocator.free(self.client.authenticator.*.credentials.client_secret);
    self.allocator.free(self.client.authenticator.*.token_source.filename);
    self.*.client.deinit();
    self.allocator.destroy(self.authenticator);
}
