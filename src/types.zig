const std = @import("std");
const Client = @import("client.zig").Client;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example: 6rqhFgbbKwnb9MLmUQDhG6
pub const SpotifyId = []const u8;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example: spotify:track:6rqhFgbbKwnb9MLmUQDhG6
pub const SpotifyUri = []const u8;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example: party
pub const SpotifyCategoryId = []const u8;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example: wizzler
pub const SpotifyUserId = []const u8;

// https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
// example URL: wizzler
pub const SpotifyUrl = []const u8;

pub const ResumePoint = struct {
    fully_played: bool,
    resume_position_ms: usize,
};

// For when Spotify returns a group of objects using pages for iteration
pub fn Paginated(comptime T: type) type {
    return struct {
        href: []const u8,
        limit: usize,
        next: ?[]const u8,
        offset: usize,
        previous: ?[]const u8,
        total: usize,
        items: []const T,

        const Self = @This();

        const Result = @import("search.zig").Result;

        // use for paging to the next set of results if any
        pub fn getNext(self: Self, alloc: std.mem.Allocator, client: *Client) !?Self {
            if (self.next) |url| {
                var request = try client.get(alloc, try std.Uri.parse(url));
                defer request.deinit();

                const response = try JsonResponse(Self).parseRequest(alloc, &request);
                return switch (response.resp) {
                    .ok => |val| val,
                    .err => error.PaginationFailed,
                };
            }
            return null;
        }

        // use for paging to the previous set of results if any
        pub fn getPrevious(self: Self, alloc: std.mem.Allocator, client: *Client) !?Self {
            if (self.previous) |url| {
                var request = try client.get(alloc, try std.Uri.parse(url));
                defer request.deinit();

                const response = try JsonResponse(Self).parseRequest(alloc, &request);
                return switch (response.resp) {
                    .ok => |val| val,
                    .err => error.PaginationFailed,
                };
            }
            return null;
        }

        // -------------------------------------------------------------
        // Should paging for Paginated work in-place like Search.Result?
        // -------------------------------------------------------------
        // Return true if page was sucessful otherwise false.
        // pub inline fn pageForward(
        //     self: *Self,
        //     alloc: std.mem.Allocator,
        //     client: *Client,
        // ) !bool {
        //     var edited: bool = false;
        //     if (self.*.next) |next_url| {
        //         var request = try client.get(alloc, try std.Uri.parse(next_url));
        //         defer request.deinit();
        //         const response = try JsonResponse(
        //             Self,
        //         ).parseRequest(alloc, &request);

        //         switch (response.resp) {
        //             .err => edited = false,
        //             .ok => |val| {
        //                 std.debug.print("offset parsed: {d}\n", .{val.offset});
        //                 self.* = val;
        //             },
        //         }
        //         edited = true;
        //     }
        //     return edited;
        // }

        // Return true if page was sucessful otherwise false.
        // pub inline fn pageBackward(
        //     self: *Self,
        //     alloc: std.mem.Allocator,
        //     client: *Client,
        // ) !bool {
        //     var edited: bool = false;

        //     if (self.*.previous) |prev_url| {
        //         var request = try client.get(alloc, try std.Uri.parse(prev_url));
        //         defer request.deinit();
        //         const response = try JsonResponse(
        //             Self,
        //         ).parseRequest(alloc, &request);

        //         switch (response.resp) {
        //             .err => edited = false,
        //             .ok => |val| {
        //                 std.debug.print("offset parsed: {d}\n", .{val.offset});
        //                 self.* = val;
        //             },
        //         }
        //         edited = true;
        //     }
        //     return edited;
        // }
    };
}

// For when Spotify returns a group of objects using cursors for iteration.
pub fn Cursored(comptime T: type) type {
    return struct {
        href: []const u8,
        limit: usize,
        next: ?[]const u8,
        cursors: std.json.Value,
        total: usize,
        items: []const T,
    };
}

const Field = std.builtin.Type.StructField;
const Decl = std.builtin.Type.Declaration;

// Create a new struct type wrapping a slice of type T with the field name set to name.
// Spotify's API will return arrays of objects in a JSON object with a specific name as the key.
//
// For example, Manyify(Artist, "artists") -> struct { artists: []const Artist }
pub fn Manyify(
    comptime T: type,
    comptime name: [:0]const u8,
) type {
    return @Type(.{
        .Struct = .{
            .layout = .auto,
            .fields = &[_]Field{
                .{
                    .name = name,
                    .type = []const T,
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(T),
                },
            },
            .decls = &[_]Decl{},
            .is_tuple = false,
        },
    });
}

// Custom JSON serialization to only include key/value
// pairs if their optional is non-null.
pub fn optionalStringify(object: anytype, writer: anytype) !void {
    try writer.beginObject();
    inline for (@typeInfo(@TypeOf(object)).Struct.fields) |s_field| {
        if (@field(object, s_field.name)) |value| {
            try writer.objectField(s_field.name);
            try writer.write(value);
        }
    }
    try writer.endObject();
}

test "optional stringify" {
    const Details = struct {
        name: ?[]const u8 = null,
        public: ?bool = null,
        collaborative: ?bool = null,
        description: ?[]const u8 = null,

        pub fn jsonStringify(self: @This(), writer: anytype) !void {
            try optionalStringify(
                self,
                writer,
            );
        }
    };

    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();

    const expected: []const struct { input: Details, output: []const u8 } = &.{
        .{
            .input = .{ .collaborative = true, .description = "this is a description", .name = "a name", .public = true },
            .output =
            \\{"name":"a name","public":true,"collaborative":true,"description":"this is a description"}
            ,
        },
        .{
            .input = .{ .collaborative = true, .name = "a name", .public = true },
            .output =
            \\{"name":"a name","public":true,"collaborative":true}
            ,
        },
        .{
            .input = .{ .name = "a name", .public = true },
            .output =
            \\{"name":"a name","public":true}
            ,
        },
        .{
            .input = .{ .name = "a name" },
            .output =
            \\{"name":"a name"}
            ,
        },
    };

    for (expected) |exp| {
        list.clearAndFree();
        try std.json.stringify(exp.input, .{}, list.writer());
        try std.testing.expect(std.mem.eql(u8, list.items, exp.output));
    }
}

pub const Error = struct {
    // have to use @"error" because of Spotify's message structure
    @"error": struct {
        status: u9,
        message: []const u8,
    },
};

// Union type to represent both a JSON parsed type T or an error JSON Response
// from the Spotify Web API. If the response is valid, the value .ok will be
// populated. If there was an error, .err will be populated.
pub fn JsonResponse(comptime T: type) type {
    return struct {
        arena: *std.heap.ArenaAllocator,
        resp: union(enum) {
            ok: T,
            err: Error,
        },

        const Self = @This();

        const default_opts: std.json.ParseOptions = .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        };

        pub fn parseRequest(alloc: std.mem.Allocator, request: *std.http.Client.Request) !Self {
            const status = request.*.response.status;
            const reader = request.*.reader();
            return parse(alloc, reader, status);
        }

        fn parse(alloc: std.mem.Allocator, reader: anytype, status: std.http.Status) !Self {
            const body = try reader.readAllAlloc(alloc, 1024 * 1024);
            defer alloc.free(body);

            const arena = try alloc.create(std.heap.ArenaAllocator);
            errdefer alloc.destroy(arena);
            arena.* = std.heap.ArenaAllocator.init(alloc);

            if (body.len == 0) {
                return .{
                    .resp = .{
                        .ok = try std.json.parseFromSliceLeaky(
                            T,
                            arena.allocator(),
                            "null",
                            default_opts,
                        ),
                    },
                    .arena = arena,
                };
            }

            const code = @intFromEnum(status);
            if (code >= 200 and code < 300) {
                const parsed = try std.json.parseFromSliceLeaky(
                    T,
                    arena.allocator(),
                    body,
                    default_opts,
                );
                return .{
                    .resp = .{ .ok = parsed },
                    .arena = arena,
                };
            }

            const parsed = try std.json.parseFromSliceLeaky(
                Error,
                arena.allocator(),
                body,
                default_opts,
            );
            return .{
                .resp = .{ .err = parsed },
                .arena = arena,
            };
        }

        pub fn deinit(self: Self) void {
            const alloc = self.arena.child_allocator;
            self.arena.deinit();
            alloc.destroy(self.arena);
        }
    };
}

test "json response parses errors and valid responses" {
    const Name = struct { name: []const u8 };
    const ok_input =
        \\{"name": "matt"}
    ;

    var stream = std.io.fixedBufferStream(ok_input);
    var resp = try JsonResponse(Name).parse(
        // arena.allocator(),
        std.testing.allocator,
        stream.reader(),
        .ok,
    );

    try std.testing.expect(resp.resp == .ok);
    try std.testing.expectEqualStrings(resp.resp.ok.name, "matt");

    const err_input =
        \\{
        \\  "error": {
        \\    "status": 404,
        \\    "message": "the resource wasn't found"
        \\  }
        \\}
    ;
    stream = std.io.fixedBufferStream(err_input);

    // don't leak
    resp.deinit();

    resp = try JsonResponse(Name).parse(
        // arena.allocator(),
        std.testing.allocator,
        stream.reader(),
        .not_found,
    );
    defer resp.deinit();

    try std.testing.expect(resp.resp == .err);
    try std.testing.expect(resp.resp.err.@"error".status == 404);
    try std.testing.expectEqualStrings(
        resp.resp.err.@"error".message,
        "the resource wasn't found",
    );
}
