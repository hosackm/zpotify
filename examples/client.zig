const std = @import("std");
const zp = @import("zpotify");

pub fn buildClient(alloc: std.mem.Allocator) !zp.Client {
    var env_map = try std.process.getEnvMap(alloc);
    defer env_map.deinit();

    const id = env_map.get("ZPOTIFY_ID").?;
    const secret = env_map.get("ZPOTIFY_SECRET").?;
    const redirect = env_map.get("ZPOTIFY_REDIRECT").?;
    const token_file = env_map.get("ZPOTIFY_TOKEN_FILE").?;

    // read Token from TOKEN_FILE
    const f = try std.fs.cwd().openFile(
        token_file,
        .{ .mode = .read_only },
    );
    defer f.close();

    const contents = try f.reader().readAllAlloc(alloc, 2048);
    defer alloc.free(contents);

    var token = try zp.Token.parse(alloc, contents);
    defer token.deinit();

    return zp.Client.init(alloc, .{
        .client = id,
        .secret = secret,
        .redirect = redirect,
        .token = token.value,
    });
}
