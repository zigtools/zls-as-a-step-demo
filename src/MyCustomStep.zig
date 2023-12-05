//! Build step to extract build info

const MyCustomStep = @This();
const std = @import("std");
const Build = std.Build;
const Step = Build.Step;

const build_runner = @import("root");
const dependencies = build_runner.dependencies;

pub const Variant = enum { hello, goodbye };

step: Step,
generated_file: Build.GeneratedFile,
variant: Variant,

pub const base_id = .custom;

pub fn create(owner: *Build, variant: Variant) *MyCustomStep {
    const self = owner.allocator.create(MyCustomStep) catch @panic("OOM");
    self.* = .{
        .step = Step.init(.{
            .id = base_id,
            .name = "MyCustomStep",
            .owner = owner,
            .makeFn = make,
        }),
        .generated_file = undefined,
        .variant = variant,
    };

    self.generated_file = .{ .step = &self.step };

    return self;
}

pub fn getOutput(self: *MyCustomStep) Build.LazyPath {
    return .{ .generated = &self.generated_file };
}

fn make(step: *Step, prog_node: *std.Progress.Node) !void {
    _ = prog_node;
    const b = step.owner;
    const self = @fieldParentPtr(MyCustomStep, "step", step);

    const hello_path = try b.cache_root.join(b.allocator, &.{"hello.zig"});
    const hello_file = try std.fs.createFileAbsolute(hello_path, .{});
    defer hello_file.close();
    try hello_file.writer().writeAll("pub const hello = \"Hi!\";");

    const goodbye_path = try b.cache_root.join(b.allocator, &.{"goodbye.zig"});
    const goodbye_file = try std.fs.createFileAbsolute(goodbye_path, .{});
    defer goodbye_file.close();
    try goodbye_file.writer().writeAll("pub const goodbye = \"Bye!\";");

    self.generated_file.path = switch (self.variant) {
        .hello => hello_path,
        .goodbye => goodbye_path,
    };
}
