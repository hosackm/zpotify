//! This example should be run to login the user and persist an authorization token
//! to disk. It will display a link and ask the user to navigate and login with
//! their credentials. The spotify oauth service will then issue a redirect back to
//! localhost for collecting the token and persisting to disk.
const std = @import("std");
const zpotify = @import("zpotify");
const Credentials = zpotify.Credentials;
const Authenticator = zpotify.Authenticator;
const TokenSource = @import("token.zig").TokenSource;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var em = try std.process.getEnvMap(alloc);
    defer em.deinit();

    const creds: Credentials = .{
        .redirect_uri = em.get("SPOTIFY_REDIRECT").?,
        .client_id = em.get("SPOTIFY_ID").?,
        .client_secret = em.get("SPOTIFY_SECRET").?,
    };

    try displayCode(alloc, creds);
    try runAuthFlow(alloc, creds);
}

fn displayCode(alloc: std.mem.Allocator, creds: Credentials) !void {
    const scope_string = try zpotify.toStringAlloc(alloc, zpotify.Everything);
    defer alloc.free(scope_string);

    var buffer: [1024:0]u8 = undefined;
    _ = std.mem.replace(
        u8,
        scope_string,
        " ",
        "%20",
        &buffer,
    );

    const url = try std.fmt.allocPrint(
        alloc,
        "{s}response_type=code&scope={s}&redirect_uri={s}&client_id={s}",
        .{
            "https://accounts.spotify.com/authorize?",
            buffer[0..],
            creds.redirect_uri,
            creds.client_id,
        },
    );
    defer alloc.free(url);

    std.debug.print(
        \\Navigate to the follow URL to authenticate:
        \\
        \\{s}
        \\
        \\
    ,
        .{url},
    );
}

pub fn runAuthFlow(alloc: std.mem.Allocator, creds: Credentials) !void {
    var auth = Authenticator(TokenSource).init(.{
        .token_source = .{
            .filename = ".token.json",
            .allocator = alloc,
        },
        .credentials = creds,
        .allocator = alloc,
    });

    // This must be the same value that was used to create the application
    // And the same value used in the body of the request when granting a token.
    const address = try std.net.Address.parseIp4("127.0.0.1", 8080);
    var listener = try address.listen(.{ .reuse_port = true });
    defer listener.deinit();
    std.debug.print("Listening for redirect on: 127.0.0.1:8080\n", .{});

    // blocks until spotify redirects to us.
    var recv_buf: [1024 * 10]u8 = undefined;
    const conn = try listener.accept();
    var server = std.http.Server.init(conn, &recv_buf);
    var req = try server.receiveHead();

    // Inform the user in their browser that the login was a success
    try req.respond("Logged in successfully!\r\n", .{});

    // Parse the code out of the query section of the URL
    const code = std.mem.trimLeft(
        u8,
        req.head.target,
        "/?code=",
    );

    try auth.token_source.acquire(creds, code);

    std.debug.print("Successfully authorized.\n", .{});
}
