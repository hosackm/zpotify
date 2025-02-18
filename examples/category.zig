const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    var client = try Client.init(alloc);
    defer client.deinit();
    const c = &client;

    {
        const id = "dinner";
        const category = try zp.Category.getOne(alloc, c, id, .{});
        printJson(category);
    }
    {
        const categories = try zp.Category.getMany(alloc, c, .{});
        printJson(categories);
    }
}
