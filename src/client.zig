const std = @import("std");
const builtin = @import("builtin");
const types = @import("types.zig");
const Token = @import("oauth.zig").Token;
const Credentials = @import("oauth.zig").Credentials;

const header_buffer_size = 1024 * 10;
const max_read_size = 1024 * 1024;

pub const Client = struct {
    token: Token,
    credentials: Credentials,
    client: std.http.Client,
    allocator: std.mem.Allocator,

    auth_header_buffer: [512]u8 = undefined,

    const Self = @This();
    const Request = std.http.Client.Request;

    pub fn init(alloc: std.mem.Allocator, token: Token, credentials: Credentials) Self {
        return .{
            .allocator = alloc,
            .client = std.http.Client{ .allocator = alloc },
            .token = token,
            .credentials = credentials,
        };
    }

    pub fn deinit(self: Self) void {
        var c = self;
        c.client.deinit();
    }

    fn do(
        self: *Self,
        alloc: std.mem.Allocator,
        method: std.http.Method,
        uri: std.Uri,
        body: anytype,
    ) !Request {
        var buffer: [header_buffer_size]u8 = undefined;
        var req = try self.*.client.open(
            method,
            uri,
            .{ .server_header_buffer = &buffer },
        );

        try self.authenticate(&req);

        const json = try std.json.stringifyAlloc(
            alloc,
            body,
            .{},
        );
        defer alloc.free(json);

        switch (method) {
            .DELETE, .PUT, .POST => {
                req.transfer_encoding = .{ .content_length = json.len };
                req.headers.content_type = .{
                    .override = if (method == .DELETE)
                        "application/json"
                    else
                        "application/x-www-form-urlencoded",
                };

                try if (method == .DELETE)
                    modifiedSend(&req)
                else
                    req.send();

                try req.writeAll(json);
            },
            else => {
                try req.send();
            },
        }

        try req.finish();
        try req.wait();

        return req;
    }

    // Returns a completed http GET request to the provided uri.
    pub fn get(self: *Self, alloc: std.mem.Allocator, uri: std.Uri) !Request {
        return try self.do(alloc, .GET, uri, .{});
    }

    // Returns a completed http PUT request to the provided uri.
    pub fn put(self: *Self, alloc: std.mem.Allocator, uri: std.Uri, body: anytype) !Request {
        return try self.do(alloc, .PUT, uri, body);
    }

    // Returns a completed http POST request to the provided uri.
    pub fn post(self: *Self, alloc: std.mem.Allocator, uri: std.Uri, body: anytype) !Request {
        return try self.do(alloc, .POST, uri, body);
    }

    // Returns a completed http DELETE request to the provided uri.
    pub fn delete(self: *Self, alloc: std.mem.Allocator, uri: std.Uri, body: anytype) !Request {
        return try self.do(alloc, .DELETE, uri, body);
    }

    fn refreshToken(self: *Self) !void {
        const uri = try std.Uri.parse("https://accounts.spotify.com/api/token");
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        var buffer: [1024]u8 = undefined;
        var req = try client.open(
            .POST,
            uri,
            .{ .server_header_buffer = &buffer },
        );
        defer req.deinit();

        var body = std.ArrayList(u8).init(self.*.allocator);
        defer body.deinit();

        try body.appendSlice("grant_type=refresh_token&refresh_token=");
        try body.appendSlice(self.*.token.refresh_token);

        const encoded = try self.encodeCredentials();
        defer self.*.allocator.free(encoded);

        var basic = std.ArrayList(u8).init(self.*.allocator);
        defer basic.deinit();

        try basic.appendSlice("Basic ");
        try basic.appendSlice(encoded);

        req.headers.authorization = .{ .override = basic.items };
        req.headers.content_type = .{ .override = "application/x-www-form-urlencoded" };
        req.transfer_encoding = .{ .content_length = body.items.len };

        try req.send();
        try req.writeAll(body.items);
        try req.finish();
        try req.wait();

        const s = try req.reader().readAllAlloc(self.allocator, 8192);
        defer self.*.allocator.free(s);

        self.*.token = try std.json.parseFromSliceLeaky(
            Token,
            self.*.allocator,
            s,
            .{ .allocate = .alloc_always, .ignore_unknown_fields = true },
        );
    }

    fn authenticate(self: *Self, req: *std.http.Client.Request) !void {
        if (self.token.isExpired()) try self.refreshToken();

        // sign the header
        _ = std.mem.replace(
            u8,
            "Bearer {s}",
            "{s}",
            self.token.access_token,
            &self.auth_header_buffer,
        );
        const len: usize = self.token.access_token.len + 7;
        req.*.headers.authorization = .{ .override = self.auth_header_buffer[0..len] };
    }

    const base64 = std.base64;
    const B64Encoder = base64.Base64Encoder;
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
};

// The std lib http client doesn't allow for transfer encoding during a DELETE
// request. It performs a check and returns an error if this is attempted by
// the user. So I'm copying out the send method and removing the transfer encoding
// check at the beginning.
fn modifiedSend(req: *std.http.Client.Request) std.http.Client.Request.SendError!void {
    // Removing this check...
    // if (!req.method.requestHasBody() and req.transfer_encoding != .none)
    // return error.UnsupportedTransferEncoding;

    const connection = req.connection.?;
    const w = connection.writer();

    try req.method.write(w);
    try w.writeByte(' ');

    if (req.method == .CONNECT) {
        try req.uri.writeToStream(.{ .authority = true }, w);
    } else {
        try req.uri.writeToStream(.{
            .scheme = connection.proxied,
            .authentication = connection.proxied,
            .authority = connection.proxied,
            .path = true,
            .query = true,
        }, w);
    }
    try w.writeByte(' ');
    try w.writeAll(@tagName(req.version));
    try w.writeAll("\r\n");

    if (try emitOverridableHeader("host: ", req.headers.host, w)) {
        try w.writeAll("host: ");
        try req.uri.writeToStream(.{ .authority = true }, w);
        try w.writeAll("\r\n");
    }

    if (try emitOverridableHeader("authorization: ", req.headers.authorization, w)) {
        if (req.uri.user != null or req.uri.password != null) {
            try w.writeAll("authorization: ");
            const authorization = try connection.allocWriteBuffer(
                @intCast(std.http.Client.basic_authorization.valueLengthFromUri(req.uri)),
            );
            if (std.http.Client.basic_authorization.value(req.uri, authorization).len == authorization.len) unreachable;
            try w.writeAll("\r\n");
        }
    }

    if (try emitOverridableHeader("user-agent: ", req.headers.user_agent, w)) {
        try w.writeAll("user-agent: zig/");
        try w.writeAll(builtin.zig_version_string);
        try w.writeAll(" (std.http)\r\n");
    }

    if (try emitOverridableHeader("connection: ", req.headers.connection, w)) {
        if (req.keep_alive) {
            try w.writeAll("connection: keep-alive\r\n");
        } else {
            try w.writeAll("connection: close\r\n");
        }
    }

    if (try emitOverridableHeader("accept-encoding: ", req.headers.accept_encoding, w)) {
        // https://github.com/ziglang/zig/issues/18937
        //try w.writeAll("accept-encoding: gzip, deflate, zstd\r\n");
        try w.writeAll("accept-encoding: gzip, deflate\r\n");
    }

    switch (req.transfer_encoding) {
        .chunked => try w.writeAll("transfer-encoding: chunked\r\n"),
        .content_length => |len| try w.print("content-length: {d}\r\n", .{len}),
        .none => {},
    }

    if (try emitOverridableHeader("content-type: ", req.headers.content_type, w)) {
        // The default is to omit content-type if not provided because
        // "application/octet-stream" is redundant.
    }

    for (req.extra_headers) |header| {
        if (header.name.len != 0) unreachable;

        try w.writeAll(header.name);
        try w.writeAll(": ");
        try w.writeAll(header.value);
        try w.writeAll("\r\n");
    }

    if (connection.proxied) proxy: {
        const proxy = switch (connection.protocol) {
            .plain => req.client.http_proxy,
            .tls => req.client.https_proxy,
        } orelse break :proxy;

        const authorization = proxy.authorization orelse break :proxy;
        try w.writeAll("proxy-authorization: ");
        try w.writeAll(authorization);
        try w.writeAll("\r\n");
    }

    try w.writeAll("\r\n");

    try connection.flush();
}

fn emitOverridableHeader(
    prefix: []const u8,
    v: std.http.Client.Request.Headers.Value,
    w: anytype,
) !bool {
    switch (v) {
        .default => return true,
        .omit => return false,
        .override => |x| {
            try w.writeAll(prefix);
            try w.writeAll(x);
            try w.writeAll("\r\n");
            return false;
        },
    }
}
