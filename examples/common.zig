const std = @import("std");

pub fn printJson(response: anytype) void {
    const w = std.io.getStdOut().writer();
    switch (response.resp) {
        .ok => |ok| std.json.stringify(
            ok,
            .{},
            w,
        ) catch unreachable,
        .err => |err| std.json.stringify(
            err,
            .{},
            w,
        ) catch unreachable,
    }
    _ = std.io.getStdOut().write("\n") catch unreachable;
}
