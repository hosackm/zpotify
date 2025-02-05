//! Shows how to create a TokenSource to pass to the Authenticator
//! as a comptime type. The authenticator doesn't care how you acquire
//! or refresh tokens. All it needs is a method called get() on
//! the type you pass in as a comptime type. This method will be
//! called whenever a token is required.
const std = @import("std");
const zpotify = @import("zpotify");

const Credentials = zpotify.Credentials;

const Token = @This();
access_token: []const u8,
refresh_token: []const u8,

pub fn deinit(self: Token, alloc: std.mem.Allocator) void {
    alloc.free(self.access_token);
    alloc.free(self.refresh_token);
}

// // Encodes a string for inclusion in a URL. Unsupported characters are converted
// // to their corresponding ASCII 2 digit hex codes preceded by a %.
// fn urlEncode(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
//     var list = std.ArrayList(u8).init(alloc);
//     const convert: []const u8 = " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{`}~";

//     for (s, 0..) |c, n| {
//         const slice = s[n .. n + 1];
//         if (!std.mem.containsAtLeast(u8, convert, 1, slice)) {
//             try list.append(c);
//             continue;
//         }
//         var buf: [3]u8 = undefined;
//         for (try std.fmt.bufPrint(&buf, "%{X}", .{c})) |ch| try list.append(ch);
//     }

//     return list.toOwnedSlice();
// }

// An example of a token source. Must have a method called "get" that
// returns []const u8 containing the access token in exchange for the
// client credentials. The authenticator will store the client credentials
// and pass them in when calling "get" to retrieve a new token.
pub const TokenSource = struct {
    // This example token source persists a token to disk
    filename: []const u8,
    allocator: std.mem.Allocator,

    // You must specify the errors that can be returned.
    pub const Error = error{Something};

    // This method must exist, and is checked at compile-time to exist.
    pub fn get(self: TokenSource, creds: Credentials) Error![]const u8 {
        // Read the token from the token.json file
        var token = self.read() catch return Error.Something;
        defer token.deinit(self.allocator);

        // Refresh the token if it's expired
        self.refresh(&token, creds) catch return Error.Something;

        // Persist to disk
        self.persist(token) catch return Error.Something;

        return self.allocator.dupe(u8, token.access_token) catch return Error.Something;
    }

    fn read(self: TokenSource) !Token {
        const f = try std.fs.cwd().openFile(self.filename, .{});
        defer f.close();

        const data = try f.reader().readAllAlloc(self.allocator, 2048);
        defer self.allocator.free(data);

        const json = try std.json.parseFromSlice(
            std.json.Value,
            self.allocator,
            data,
            .{},
        );
        defer json.deinit();

        return .{
            .access_token = try self.allocator.dupe(
                u8,
                json.value.object.get("access_token").?.string,
            ),
            .refresh_token = try self.allocator.dupe(
                u8,
                json.value.object.get("refresh_token").?.string,
            ),
        };
    }

    fn refresh(self: TokenSource, token: *Token, creds: Credentials) !void {
        // Not quite working...
        // if (!try self.isExpired()) return;

        const uri = try std.Uri.parse("https://accounts.spotify.com/api/token");
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        var buffer: [1024 * 1024 * 4]u8 = undefined;
        var req = try client.open(
            .POST,
            uri,
            .{ .server_header_buffer = &buffer },
        );
        defer req.deinit();

        const body = try std.fmt.allocPrint(
            self.allocator,
            "grant_type=refresh_token&refresh_token={s}",
            .{token.*.refresh_token},
        );
        defer self.allocator.free(body);

        const enc = std.base64.Base64Encoder{
            .alphabet_chars = std.base64.standard_alphabet_chars,
            .pad_char = null,
        };
        const joined_creds = try std.mem.join(
            self.allocator,
            ":",
            &.{ creds.client_id, creds.client_secret },
        );
        defer self.allocator.free(joined_creds);

        const b64buffer = try self.allocator.alloc(u8, enc.calcSize(joined_creds.len));
        defer self.allocator.free(b64buffer);

        const encoded = enc.encode(b64buffer, joined_creds);
        const basic = try std.fmt.allocPrint(self.allocator, "Basic {s}", .{encoded});
        defer self.allocator.free(basic);

        req.headers.authorization = .{ .override = basic };
        req.headers.content_type = .{ .override = "application/x-www-form-urlencoded" };
        req.transfer_encoding = .{ .content_length = body.len };

        try req.send();
        try req.writeAll(body[0..]);
        try req.finish();
        try req.wait();

        const s = try req.reader().readAllAlloc(self.allocator, 8192);
        defer self.allocator.free(s);

        const parsed = try std.json.parseFromSlice(std.json.Value, self.allocator, s, .{});
        defer parsed.deinit();

        const new_token = parsed.value.object.get("access_token").?.string;
        self.allocator.free(token.*.access_token);
        token.*.access_token = try self.allocator.dupe(u8, new_token);
    }

    fn persist(self: TokenSource, token: Token) !void {
        const f = try std.fs.cwd().openFile(
            self.filename,
            .{ .mode = .write_only },
        );
        defer f.close();
        try f.setEndPos(0);

        var buffer: [1000]u8 = undefined;
        try f.writer().writeAll(
            try std.fmt.bufPrint(
                &buffer,
                "{{\"access_token\":\"{s}\",\"refresh_token\":\"{s}\"}}",
                .{ token.access_token, token.refresh_token },
            ),
        );
    }

    fn isExpired(self: TokenSource) !bool {
        const f = try std.fs.cwd().openFile(self.filename, .{});
        defer f.close();
        const stat = try f.stat();

        const expires_after = std.time.ns_per_hour; // spotify tokens expire in an hour
        const padding = std.time.ns_per_min * 5; // we'll renew anything that will expire in the next 5 minutes

        return (std.time.nanoTimestamp() - stat.mtime) > (expires_after - padding);
    }

    // Only use this method when you are acquiring a Token for the first
    // time by going through the OAuth authentication flow.
    pub fn acquire(self: TokenSource, creds: Credentials, code: []const u8) !void {
        const uri = try std.Uri.parse("https://accounts.spotify.com/api/token");
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        var buffer: [1024 * 1024 * 4]u8 = undefined;
        var req = try client.open(
            .POST,
            uri,
            .{ .server_header_buffer = &buffer },
        );
        defer req.deinit();

        const escaped = try zpotify.urls.escape(self.allocator, creds.redirect_uri);
        defer self.allocator.free(escaped);

        const body = try std.fmt.allocPrint(
            self.allocator,
            "grant_type=authorization_code&code={s}&redirect_uri={s}",
            .{ code, escaped },
        );
        defer self.allocator.free(body);

        const enc = std.base64.Base64Encoder{
            .alphabet_chars = std.base64.standard_alphabet_chars,
            .pad_char = null,
        };
        const b64input = try std.mem.join(
            self.allocator,
            ":",
            &.{ creds.client_id, creds.client_secret },
        );
        defer self.allocator.free(b64input);

        const buf = try self.allocator.alloc(u8, enc.calcSize(b64input.len));
        defer self.allocator.free(buf);

        const encoded = enc.encode(buf, b64input);
        const basic = try std.fmt.allocPrint(self.allocator, "Basic {s}", .{encoded});
        defer self.allocator.free(basic);

        req.headers.authorization = .{ .override = basic };
        req.headers.content_type = .{ .override = "application/x-www-form-urlencoded" };
        req.transfer_encoding = .{ .content_length = body.len };

        try req.send();
        try req.writeAll(body[0..]);
        try req.finish();
        try req.wait();

        const s = try req.reader().readAllAlloc(self.allocator, 8192);
        defer self.allocator.free(s);

        const parsed = try std.json.parseFromSlice(
            std.json.Value,
            self.allocator,
            s,
            .{},
        );
        defer parsed.deinit();

        try self.persist(.{
            .access_token = parsed.value.object.get("access_token").?.string,
            .refresh_token = parsed.value.object.get("refresh_token").?.string,
        });
    }
};
