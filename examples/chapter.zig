const std = @import("std");
const zp = @import("zpotify");
const buildClient = @import("client.zig").buildClient;
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const alloc = gpa.allocator();

    var client = try buildClient(alloc);
    defer client.deinit();
    const c = &client;

    // Hitchiker's Guide
    // https://open.spotify.com/show/6yI0Np2UyigswnRqjSKN5V?si=bbd3a9c44f4e4d41
    const one = "4P3b73KGNxOZHIDFTKRLoT";
    const another = "5zD0AIMbpgCZgY56JSYhYl";

    {
        // get a chapter by it's id
        const chapter = try zp.Chapter.getOne(alloc, c, one, .{});
        defer chapter.deinit();
        printJson(chapter);
    }

    {
        // get multiple chapters by their ids
        const chapters = try zp.Chapter.getMany(alloc, c, &.{ one, another }, .{});
        defer chapters.deinit();
        printJson(chapters);
    }
}
