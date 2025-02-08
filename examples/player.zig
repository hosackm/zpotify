const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    const client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    // {
    //     // get a playlist by it's id
    //     if (try zp.Player.get(alloc, c, .{})) |player| {
    //         defer player.deinit();
    //         try std.json.stringify(
    //             player.value,
    //             .{},
    //             std.io.getStdOut().writer(),
    //         );
    //     } else {
    //         _ = try std.io.getStdOut().writeAll("null");
    //     }
    //     _ = try std.io.getStdOut().writeAll("\n");
    // }
    {
        // get a playlist by it's id
        const devices = try zp.Player.getDevices(alloc, c);
        defer devices.deinit();

        // try std.json.stringify(
        //     devices.value,
        //     .{},
        //     std.io.getStdOut().writer(),
        // );
        // _ = try std.io.getStdOut().writeAll("\n");

        if (devices.value.devices.len > 0) {
            const device_id = devices.value.devices[0].id;
            const player_state = try zp.Player.currentlyPlaying(alloc, c, .{});
            defer player_state.deinit();

            if (player_state.value.is_playing) {
                std.debug.print("was playing -> pausing...\n", .{});
                try zp.Player.pause(alloc, c, device_id);
            } else {
                std.debug.print("was paused -> playing...\n", .{});
                try zp.Player.play(alloc, c, device_id);
            }
        } else {
            std.debug.print("no device found. start one to test.\n", .{});
        }
    }
}
