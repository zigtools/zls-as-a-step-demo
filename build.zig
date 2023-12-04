const std = @import("std");
const zls = @import("zls");
const MyCustomStep = @import("src/MyCustomStep.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const my_custom_step = MyCustomStep.create(b);

    const exe = b.addExecutable(.{
        .name = "zls-as-step",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.step.dependOn(&my_custom_step.step);
    exe.addAnonymousModule("hello", .{ .source_file = my_custom_step.getOutput() });
    exe.addAnonymousModule("my-package", .{ .source_file = .{ .path = "my-package/lib.zig" } });
    b.installArtifact(exe);

    const extract_build_info = zls.ExtractBuildInfo.create(b, .{});

    // Depend on everything you want ZLS to be able to complete
    extract_build_info.step.dependOn(&exe.step);

    const install_zls = b.addInstallArtifact(b.dependency("zls", .{}).artifact("zls"), .{});
    install_zls.step.dependOn(&extract_build_info.step);

    const tooling_step = b.step("install-zls", "Install tooling (ZLS)");
    tooling_step.dependOn(&install_zls.step);
}
