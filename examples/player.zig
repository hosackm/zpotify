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
        // get the user's player object
        const player_resp = try zp.Player.get(alloc, c, .{});
        switch (player_resp.resp) {
            .ok => printJson(player_resp),
            .err => {},
        }
    }

    {
        // get the current device and toggle the playback from play/paused
        const toggle: bool = true;
        const devices = try zp.Player.getDevices(alloc, c);

        switch (devices.resp) {
            .ok => |ok| {
                if (ok.devices.len > 0) {
                    const device_id = ok.devices[0].id;
                    const player_state = try zp.Player.currentlyPlaying(alloc, c, .{});

                    if (toggle) {
                        switch (player_state.resp) {
                            .ok => |state_opt| {
                                if (state_opt) |state| {
                                    if (state.is_playing) {
                                        std.debug.print("pausing...\n", .{});
                                        try zp.Player.pause(alloc, c, device_id);
                                    } else {
                                        std.debug.print("playing...\n", .{});
                                        try zp.Player.play(alloc, c, device_id);
                                    }
                                }
                            },
                            else => {},
                        }
                    }
                } else std.debug.print("no device found. start one to test.\n", .{});
            },
            .err => std.debug.print("error while getting devices\n", .{}),
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

fn getDevice(alloc: std.mem.Allocator, client: *zp.Client) !?[]const u8 {
    const devices = try zp.Player.getDevices(alloc, client);
    switch (devices.resp) {
        .ok => |ok| if (ok.devices.len > 0) return try alloc.dupe(u8, ok.devices[0].id),
        else => {},
    }
    return null;
}
