const std = @import("std");

pub fn printJson(object: anytype) !void {
    try std.json.stringify(
        object.value,
        .{},
        std.io.getStdOut().writer(),
    );
    _ = try std.io.getStdOut().write("\n");
}
