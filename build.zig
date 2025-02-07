const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zpotify = b.addModule(
        "zpotify",
        .{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        },
    );

    // Examples
    const Example = enum {
        audiobook,
        auth,
        artist,
        album,
        chapter,
        episode,
        playlist,
        player,
        show,
        track,
        user,
    };
    const example_option = b.option(Example, "example", "Example to run (default: auth)") orelse .auth;
    const example_step = b.step("example", "Run example");
    const example = b.addExecutable(.{
        .name = "example",
        // future versions should use b.path, see zig PR #19597
        .root_source_file = b.path(
            b.fmt("examples/{s}.zig", .{@tagName(example_option)}),
        ),
        .target = target,
        .optimize = optimize,
    });
    example.root_module.addImport("zpotify", zpotify);

    const example_run = b.addRunArtifact(example);
    example_step.dependOn(&example_run.step);
}
