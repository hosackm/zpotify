const std = @import("std");

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

// Copies a dynamic JSON object by using comptime type reflection.
fn deepCopy(comptime T: type, v: std.json.Value) T {
    _ = v;
    return .{};
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
