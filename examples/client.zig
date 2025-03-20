const std = @import("std");
const zp = @import("zpotify");

// Build client using environment variables and token file contents
pub fn buildClient(alloc: std.mem.Allocator) !zp.Client {
    var env_map = try std.process.getEnvMap(alloc);
    defer env_map.deinit();

    const token = try buildToken(alloc, env_map.get("ZPOTIFY_TOKEN_FILE").?);
    defer token.deinit();

    return zp.Client.init(alloc, .{
        .client = env_map.get("ZPOTIFY_ID").?,
        .secret = env_map.get("ZPOTIFY_SECRET").?,
        .redirect = env_map.get("ZPOTIFY_REDIRECT").?,
        .token = token.value,
    });
}

// Read contents from token file and return parsed Token
fn buildToken(alloc: std.mem.Allocator, filename: []const u8) !std.json.Parsed(zp.Token) {
    const f = try std.fs.cwd().openFile(
        filename,
        .{ .mode = .read_only },
    );
    defer f.close();

    const contents = try f.reader().readAllAlloc(alloc, 2048);
    defer alloc.free(contents);

    return try zp.Token.parse(alloc, contents);
}
