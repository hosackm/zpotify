const std = @import("std");
const builtin = @import("builtin");

pub fn Client(comptime T: type) type {
    return struct {
        authenticator: *T,
        max_read_size: usize = 1024 * 1024,

        pub fn get(
            self: @This(),
            alloc: std.mem.Allocator,
            uri: std.Uri,
        ) ![]const u8 {
            var client = std.http.Client{ .allocator = alloc };
            defer client.deinit();

            var buffer: [1024 * 10]u8 = undefined;
            var req = try client.open(
                .GET,
                uri,
                .{ .server_header_buffer = &buffer },
            );
            defer req.deinit();

            try self.authenticator.authenticate(&req);
            try req.send();
            try req.wait();
            try req.finish();

            switch (req.response.status) {
                // 200, 201, 202, 204
                .ok, .created, .accepted, .no_content => {
                    std.debug.print("client: ok!\n", .{});
                },
                // 400, 401, 403, 404, 429
                .bad_request, .unauthorized, .forbidden, .not_found, .too_many_requests => {
                    std.debug.print("client: user error - {s}\n", .{req.response.reason});
                },
                // 500, 502, 503
                .internal_server_error, .bad_gateway, .service_unavailable => {
                    std.debug.print("client: server error\n", .{});
                },
                else => {
                    std.debug.print("unhandled - {d}\n", .{req.response.status});
                    unreachable;
                },
            }

            return try req.reader().readAllAlloc(
                alloc,
                self.max_read_size,
            );
        }

        pub fn put(
            self: @This(),
            alloc: std.mem.Allocator,
            uri: std.Uri,
            body: anytype,
        ) ![]const u8 {
            var client = std.http.Client{ .allocator = alloc };
            defer client.deinit();

            var buffer: [1024 * 10]u8 = undefined;
            var req = try client.open(
                .PUT,
                uri,
                .{ .server_header_buffer = &buffer },
            );
            defer req.deinit();

            const json = try std.json.stringifyAlloc(
                alloc,
                body,
                .{},
            );
            defer alloc.free(json);

            req.transfer_encoding = .{ .content_length = json.len };
            req.headers.content_type = .{ .override = "application/x-www-form-urlencoded" };
            try self.authenticator.authenticate(&req);

            try req.send();
            try req.writeAll(json);
            try req.finish();
            try req.wait();

            switch (req.response.status) {
                .ok, .created, .accepted, .no_content => {
                    std.debug.print("client: ok!\n", .{});
                },
                .bad_request, .unauthorized, .forbidden, .not_found, .too_many_requests => {
                    std.debug.print("client: user error - {s}\n", .{req.response.reason});
                },
                .internal_server_error, .bad_gateway, .service_unavailable => {
                    std.debug.print("server error\n", .{});
                },
                else => unreachable,
            }

            return try req.reader().readAllAlloc(
                alloc,
                self.max_read_size,
            );
        }

        pub fn post(
            self: @This(),
            alloc: std.mem.Allocator,
            uri: std.Uri,
            body: anytype,
        ) ![]const u8 {
            var client = std.http.Client{ .allocator = alloc };
            defer client.deinit();

            var buffer: [1024 * 10]u8 = undefined;
            var req = try client.open(
                .POST,
                uri,
                .{ .server_header_buffer = &buffer },
            );
            defer req.deinit();

            const json = try std.json.stringifyAlloc(
                alloc,
                body,
                .{},
            );
            defer alloc.free(json);

            req.transfer_encoding = .{ .content_length = json.len };
            req.headers.content_type = .{ .override = "application/x-www-form-urlencoded" };
            try self.authenticator.authenticate(&req);

            try req.send();
            try req.writeAll(json);
            try req.finish();
            try req.wait();

            switch (req.response.status) {
                .ok, .created, .accepted, .no_content => {
                    std.debug.print("client: ok!\n", .{});
                },
                .bad_request, .unauthorized, .forbidden, .not_found, .too_many_requests => {
                    std.debug.print("client: user error - {s}\n", .{req.response.reason});
                },
                .internal_server_error, .bad_gateway, .service_unavailable => {
                    std.debug.print("server error\n", .{});
                },
                else => unreachable,
            }

            return try req.reader().readAllAlloc(
                alloc,
                self.max_read_size,
            );
        }

        pub fn delete(
            self: @This(),
            alloc: std.mem.Allocator,
            uri: std.Uri,
            body: anytype,
        ) ![]const u8 {
            var client = std.http.Client{ .allocator = alloc };
            defer client.deinit();

            var buffer: [1024 * 10]u8 = undefined;
            var req = try client.open(
                .DELETE,
                uri,
                .{ .server_header_buffer = &buffer },
            );
            defer req.deinit();

            const json = try std.json.stringifyAlloc(
                alloc,
                body,
                .{},
            );
            defer alloc.free(json);

            req.headers.content_type = .{ .override = "application/json" };
            try self.authenticator.authenticate(&req);

            // can't use chunked? must set content length header explicitly
            req.transfer_encoding = .{ .content_length = json.len };

            // try req.send();
            try mySend(&req);
            try req.writeAll(json);
            try req.finish();
            try req.wait();

            switch (req.response.status) {
                // 200
                .ok, .created, .accepted, .no_content => {
                    std.debug.print("client: ok!\n", .{});
                },
                // 400, 401, 403, 404, 429
                .bad_request, .unauthorized, .forbidden, .not_found, .too_many_requests => {
                    std.debug.print("client: user error - {s}\n", .{req.response.reason});
                },
                // 500, 502, 503
                .internal_server_error, .bad_gateway, .service_unavailable => {
                    std.debug.print("server error\n", .{});
                },
                else => {
                    std.debug.print("uncaught status code - {d}\n", .{req.response.status});
                    @panic("hmmmm....");
                },
            }

            return try req.reader().readAllAlloc(
                alloc,
                self.max_read_size,
            );
        }
    };
}

fn mySend(req: *std.http.Client.Request) std.http.Client.Request.SendError!void {
    // Skip this for a DELETE!
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
