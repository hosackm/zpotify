const std = @import("std");
const zpotify = @import("zpotify");
const Authenticator = zpotify.Authenticator;
// const TokenSource = zpotify.TokenSource;
const TokenSource = @import("token.zig").TokenSource;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var em = try std.process.getEnvMap(alloc);
    defer em.deinit();

    var auth = Authenticator(TokenSource).init(.{
        .token_source = .{
            .filename = ".token.json",
            .allocator = alloc,
        },
        .credentials = .{
            .redirect_uri = em.get("SPOTIFY_ID").?,
            .client_id = em.get("SPOTIFY_ID").?,
            .client_secret = em.get("SPOTIFY_SECRET").?,
        },
        .allocator = alloc,
    });

    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();

    var buffer: [1024 * 10]u8 = undefined;

    var req = try client.open(
        .GET,
        try std.Uri.parse("https://api.spotify.com/v1/me/top/artists"),
        .{ .server_header_buffer = &buffer },
    );
    defer req.deinit();

    try auth.authenticate(&req);
    try req.send();
    try req.wait();
    const body = try req.reader().readAllAlloc(alloc, 1024 * 1024 * 8);
    defer alloc.free(body);

    try std.io.getStdOut().writeAll(body);
}
