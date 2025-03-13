const std = @import("std");
const zp = @import("zpotify");

// env_map variables should live as long as the client
var env_map: ?std.process.EnvMap = null;

pub fn init(alloc: std.mem.Allocator) !zp.Client {
    env_map = try std.process.getEnvMap(alloc);
    const id = env_map.?.get("ZPOTIFY_ID").?;
    const secret = env_map.?.get("ZPOTIFY_SECRET").?;
    const redirect = env_map.?.get("ZPOTIFY_REDIRECT").?;
    const token_file = env_map.?.get("ZPOTIFY_TOKEN_FILE").?;

    const creds: zp.Credentials = .{
        .client_id = id,
        .client_secret = secret,
        .redirect_uri = redirect,
    };

    // read Token from TOKEN_FILE
    const f = try std.fs.cwd().openFile(
        token_file,
        .{ .mode = .read_only },
    );
    defer f.close();

    const contents = try f.reader().readAllAlloc(alloc, 2048);
    defer alloc.free(contents);

    const token = try zp.Token.parse(alloc, contents);

    return zp.Client.init(alloc, token, creds);
}

pub fn deinit() void {
    if (env_map) |em| em.deinit();
}
