const std = @import("std");
const builtin = @import("builtin");
const types = @import("types.zig");

const header_buffer_size = 1024 * 10;
const max_read_size = 1024 * 1024;

pub fn Client(comptime T: type) type {
    return struct {
        authenticator: *T,
        client: std.http.Client,

        const Self = @This();
        const Request = std.http.Client.Request;

        pub fn init(alloc: std.mem.Allocator, auth: *T) Self {
            return .{
                .client = std.http.Client{ .allocator = alloc },
                .authenticator = auth,
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

            try self.authenticator.authenticate(&req);

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
    };
}

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
