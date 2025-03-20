const std = @import("std");
const zp = @import("zpotify");

credentials: zp.Credentials,
allocator: std.mem.Allocator,

const Self = @This();

// Because std.json.parseFromSliceLeaky is used, an ArenaAllocator should be
// used to ensure deep recursive memory allocations are freed properly.
pub fn init(alloc: std.mem.Allocator, credentials: zp.Credentials) Self {
    return .{
        .allocator = alloc,
        .credentials = credentials,
    };
}

// Exchanges a code for an access token.
pub fn exchange(self: Self, code: []const u8) !std.json.Parsed(zp.Token) {
    var client = std.http.Client{ .allocator = self.allocator };
    defer client.deinit();

    var auth_header = std.ArrayList(u8).init(self.allocator);
    defer auth_header.deinit();

    const encoded = try self.encodeCredentials();
    defer self.allocator.free(encoded);

    try auth_header.appendSlice("Basic ");
    try auth_header.appendSlice(encoded);

    // build request
    var buffer: [1024]u8 = undefined;
    var request = try client.open(
        .POST,
        try std.Uri.parse("https://accounts.spotify.com/api/token"),
        .{
            .headers = .{
                .content_type = .{
                    .override = "application/x-www-form-urlencoded",
                },
                .authorization = .{ .override = auth_header.items },
            },
            .server_header_buffer = &buffer,
        },
    );
    defer request.deinit();

    // write body
    const body = try self.exchangeBody(code);
    defer self.allocator.free(body);

    request.transfer_encoding = .{ .content_length = body.len };

    // send
    try request.send();
    try request.writeAll(body[0..]);
    try request.finish();
    try request.wait();

    // read
    const max_token_size: usize = 1024; // this is enough in my testing. including all possible scopes.
    const data = try request.reader().readAllAlloc(
        self.allocator,
        max_token_size,
    );
    defer self.allocator.free(data);

    return try zp.Token.parse(self.allocator, data);
}

const base64 = std.base64;
const B64Encoder = base64.Base64Encoder;

// Base64 encodes client id and client secret
fn encodeCredentials(self: Self) ![]const u8 {
    const enc = B64Encoder{
        .alphabet_chars = base64.standard_alphabet_chars,
        .pad_char = null,
    };

    var input = std.ArrayList(u8).init(self.allocator);
    defer input.deinit();

    try input.appendSlice(self.credentials.client_id);
    try input.append(':');
    try input.appendSlice(self.credentials.client_secret);

    const buffer = try self.allocator.alloc(u8, enc.calcSize(input.items.len));
    defer self.allocator.free(buffer);

    return self.allocator.dupe(u8, enc.encode(buffer, input.items));
}

fn exchangeBody(self: Self, code: []const u8) ![]const u8 {
    var body = std.ArrayList(u8).init(self.allocator);
    defer body.deinit();

    try body.appendSlice("grant_type=authorization_code&code=");
    try body.appendSlice(code);
    try body.appendSlice("&redirect_uri=");

    const escaped = try zp.escape(
        self.allocator,
        self.credentials.redirect_uri,
    );
    defer self.allocator.free(escaped);
    try body.appendSlice(escaped);
    return body.toOwnedSlice();
}
