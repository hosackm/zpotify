//! Markets from the web API reference
const std = @import("std");
const types = @import("types.zig");
const base_url = @import("url.zig").base_url;
const Client = @import("client.zig").Client;

const Markets = struct { markets: []const []const u8 };

pub fn list(alloc: std.mem.Allocator, client: *Client) !types.JsonResponse(Markets) {
    var request = try client.get(alloc, try std.Uri.parse(base_url ++ "/markets"));
    defer request.deinit();
    return types.JsonResponse(Markets).parse(alloc, &request);
}
