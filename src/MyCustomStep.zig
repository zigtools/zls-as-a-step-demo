//! Build step to extract build info

const MyCustomStep = @This();
const std = @import("std");
const Build = std.Build;
const Step = Build.Step;

const build_runner = @import("root");
const dependencies = build_runner.dependencies;

step: Step,
generated_file: Build.GeneratedFile,

pub const base_id = .custom;

pub fn create(owner: *Build) *MyCustomStep {
    const self = owner.allocator.create(MyCustomStep) catch @panic("OOM");
    self.* = .{
        .step = Step.init(.{
            .id = base_id,
            .name = "MyCustomStep",
            .owner = owner,
            .makeFn = make,
        }),
        .generated_file = undefined,
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

    self.generated_file.path = try b.cache_root.join(b.allocator, &.{"hello.zig"});

    const file = try std.fs.createFileAbsolute(self.generated_file.path.?, .{});
    defer file.close();

    try file.writer().writeAll("pub const hello = \"Hi!\";");
}
