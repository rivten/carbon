const std = @import("std");
const builtin = @import("builtin");

const build_root = "../build/";
const cache_root = "../build/cache/";

const is_windows = builtin.os == builtin.Os.windows;

pub fn build(b: *std.build.Builder) void {
    b.build_root = build_root;
    b.cache_root = cache_root;
    b.release_mode = builtin.Mode.Debug;

    const mode = b.standardReleaseOptions();

    var exe = b.addExecutable("carbon", "../code/carbon.zig");
    exe.setOutputDir(build_root);
    exe.addIncludeDir("../code/");
    exe.setBuildMode(mode);
    exe.addCSourceFile("../code/sokol_compile.c", [_][]const u8{"-std=c99"});

    exe.linkSystemLibrary("c");
    if (is_windows) {
        exe.addObjectFile("cimgui.obj");
        exe.addObjectFile("imgui.obj");
        exe.addObjectFile("imgui_demo.obj");
        exe.addObjectFile("imgui_draw.obj");
        exe.addObjectFile("imgui_widgets.obj");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
    } else {
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("GLEW");
    }

    var run_step = exe.run();
    run_step.step.dependOn(&exe.step);

    b.default_step.dependOn(&run_step.step);
}
