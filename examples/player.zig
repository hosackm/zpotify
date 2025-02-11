const std = @import("std");
const zp = @import("zpotify");
const Client = @import("client.zig");
const printJson = @import("common.zig").printJson;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) std.debug.print("LEAK!\n", .{});

    var client = try Client.init(alloc);
    defer client.deinit();
    const c = &client.client;

    {
        // get the user's player object
        if (try zp.Player.get(alloc, c, .{})) |player| {
            defer player.deinit();
            try printJson(player);
        } else {
            _ = try std.io.getStdOut().writeAll("null\n");
        }
    }

    {
        // get the current device and toggle the playback from play/paused
        const toggle: bool = false;
        const devices = try zp.Player.getDevices(alloc, c);
        defer devices.deinit();

        if (devices.value.devices.len > 0) {
            const device_id = devices.value.devices[0].id;
            const player_state = try zp.Player.currentlyPlaying(alloc, c, .{});
            defer player_state.deinit();

            if (toggle) {
                if (player_state.value.is_playing) {
                    std.debug.print("was playing -> pausing...\n", .{});
                    try zp.Player.pause(alloc, c, device_id);
                } else {
                    std.debug.print("was paused -> playing...\n", .{});
                    try zp.Player.play(alloc, c, device_id);
                }
            } else try printJson(player_state);
        } else {
            std.debug.print("no device found. start one to test.\n", .{});
        }
    }

    {
        // get the current device and toggle the playback from play/paused
        const device = try getDevice(alloc, c);
        if (device) |dev| {
            defer alloc.free(dev);
            // toggle a setting or seek to a track etc.
            // try zp.Player.seekTo(alloc, c, dev, 1);
            // try zp.Player.next(alloc, c, dev);
            // try zp.Player.previous(alloc, c, dev);
            // try zp.Player.setRepeat(alloc, c, dev, .track);
            // try zp.Player.setVolume(alloc, c, dev, 95);
            // try zp.Player.setShuffle(alloc, c, dev, true);
            std.debug.print("{s}\n", .{dev});
        } else {
            std.debug.print("No device available.\n", .{});
        }
    }
}

fn getDevice(alloc: std.mem.Allocator, client: anytype) !?[]const u8 {
    const devices = try zp.Player.getDevices(alloc, client);
    defer devices.deinit();
    return if (devices.value.devices.len > 0)
        try alloc.dupe(u8, devices.value.devices[0].id)
    else
        null;
}
