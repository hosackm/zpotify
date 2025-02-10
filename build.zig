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
    const Examples = enum {
        all,
        audiobook,
        auth,
        artist,
        album,
        category,
        chapter,
        episode,
        playlist,
        player,
        search,
        show,
        track,
        user,
    };

    const example_step = b.step("examples", "Run example");
    const example_option = b.option(
        Examples,
        "example",
        "Example to run (default: auth)",
    ) orelse .auth;

    const is_build_all = std.mem.eql(u8, "all", @tagName(example_option));

    inline for (@typeInfo(Examples).Enum.fields) |e_field| {
        // don't attempt to build "all" as a target, it's not one.
        if (!std.mem.eql(u8, e_field.name, "all")) {
            if (is_build_all or std.mem.eql(u8, @tagName(example_option), e_field.name)) {
                const example = b.addExecutable(.{
                    .name = e_field.name,
                    .root_source_file = b.path("examples/" ++ e_field.name ++ ".zig"),
                    .target = target,
                    .optimize = optimize,
                });
                example.root_module.addImport("zpotify", zpotify);
                b.installArtifact(example);
                example_step.dependOn(b.getInstallStep());

                if (!is_build_all) {
                    const example_run = b.addRunArtifact(example);
                    example_step.dependOn(&example_run.step);
                }
            }
        }
    }
}
