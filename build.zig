const std = @import("std");

const BuildType = enum { static, dynamic };
const Binding = enum { zig, c, cpp, rust };

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const use_llvm = b.option(bool, "use_llvm", "Use Zig's llvm code backend") orelse true;
    const enable_bench = b.option(
        bool,
        "bench",
        "Enable benchmark mode",
    ) orelse false;
    _ = enable_bench; // autofix
    const example_name = b.option(
        []const u8,
        "name",
        "Example name",
    );

    const root_source = b.path("src/root.zig");
    const farbe_module = b.addModule("farbe", .{
        .root_source_file = root_source,
    });

    const binding = determineBinding(b, example_name);
    const build_type = b.option(
        BuildType,
        "type",
        "Build type (static, dynamic)",
    ) orelse .static;

    const run_step = b.step("run", "Run example");

    // check step for better diagnostics
    const check = b.addExecutable(.{
        .name = "check",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const check_step = b.step("check", "Check if foo compiles");
    check_step.dependOn(&check.step);

    const lib = createLibrary(
        b,
        binding,
        build_type,
        root_source,
        target,
        optimize,
        use_llvm,
    );
    setupLibrary(b, lib, binding, farbe_module);
    b.installArtifact(lib);

    if (binding == .rust) {
        try setupRustBindings(b, lib, target, build_type);
    }

    const bench = b.addExecutable(.{
        .name = "bench",
        .root_source_file = b.path("bench/main.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    bench.root_module.addImport("farbe", farbe_module);

    const run_bench = b.addRunArtifact(bench);
    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&run_bench.step);

    const main_tests = b.addTest(.{
        .root_source_file = b.path("test/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_tests.root_module.addImport("farbe", farbe_module);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(main_tests).step);

    if (example_name) |name| {
        const example = try setupExample(b, name, binding, target, optimize, lib, farbe_module);
        if (example) |ex| {
            run_step.dependOn(&ex.step);
        }
    }
}

fn determineBinding(b: *std.Build, example_name: ?[]const u8) Binding {
    const binding = b.option(
        Binding,
        "binding",
        "Binding type (zig, c, cpp, rust)",
    ) orelse .zig;

    if (example_name) |name| {
        const paths = .{
            .{ "Cargo.toml", Binding.rust },
            .{ "main.cpp", Binding.cpp },
            .{ "main.c", Binding.c },
            .{ "main.zig", Binding.zig },
        };

        inline for (paths) |path_info| {
            const path = b.fmt("examples/{s}/{s}", .{ name, path_info[0] });
            if (fileExists(path)) return path_info[1];
        }
    }

    return binding;
}

fn createLibrary(
    b: *std.Build,
    binding: Binding,
    build_type: BuildType,
    root_source: std.Build.LazyPath,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    use_llvm: bool,
) *std.Build.Step.Compile {
    const source = switch (binding) {
        .zig => root_source,
        else => b.path("src/exports.zig"),
    };

    const lib = switch (build_type) {
        .static => b.addStaticLibrary(.{
            .name = "farbe",
            .root_source_file = source,
            .target = target,
            .optimize = optimize,
            .use_lld = use_llvm,
            .use_llvm = use_llvm,
        }),
        .dynamic => b.addSharedLibrary(.{
            .name = "farbe",
            .root_source_file = source,
            .target = target,
            .optimize = optimize,
            .version = .{ .major = 0, .minor = 0, .patch = 1 },
            .use_lld = use_llvm,
            .use_llvm = use_llvm,
        }),
    };

    lib.root_module.strip = true;
    lib.root_module.omit_frame_pointer = true;

    if (target.result.os.tag == .windows) {
        lib.root_module.stack_protector = false;
        lib.root_module.stack_check = false;
    }

    switch (binding) {
        .rust => setupRustCompilerFlags(lib, target, build_type),
        .c, .cpp => {
            lib.linkLibC();
            lib.bundle_compiler_rt = true;
            if (binding == .cpp) lib.linkLibCpp();
        },
        .zig => {},
    }

    return lib;
}

fn setupRustCompilerFlags(
    lib: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    build_type: BuildType,
) void {
    if (target.result.os.tag == .windows) {
        if (build_type == .static) {
            lib.linkage = .static;
            lib.bundle_compiler_rt = true;
            lib.want_lto = false;

            lib.linkLibCpp();
            lib.linkLibC();

            lib.subsystem = .Windows;

            lib.dead_strip_dylibs = false;
        } else {
            lib.bundle_compiler_rt = true;
            lib.linkage = .dynamic;
            lib.linker_allow_shlib_undefined = true;
            lib.linkLibC();
        }
    } else {
        lib.bundle_compiler_rt = true;
        lib.linker_allow_shlib_undefined = true;
        lib.linkLibC();
    }
}

fn setupRustBindings(
    b: *std.Build,
    lib: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    build_type: BuildType,
) !void {
    const feature_flag = if (build_type == .static)
        "--features=static"
    else
        "--features=dynamic";

    const cargo = b.addSystemCommand(&[_][]const u8{
        "cargo",
        "build",
        "--manifest-path",
        "include/rust/Cargo.toml",
        feature_flag,
        "--verbose",
    });

    if (target.result.os.tag == .windows and build_type == .static) {
        cargo.setEnvironmentVariable("RUSTFLAGS", "-Ctarget-feature=+crt-static");
    }

    cargo.step.dependOn(&lib.step);
    b.getInstallStep().dependOn(&cargo.step);
}

fn setupLibrary(
    b: *std.Build,
    lib: *std.Build.Step.Compile,
    binding: Binding,
    farbe_module: *std.Build.Module,
) void {
    if (binding == .zig) return;

    lib.root_module.addImport("farbe", farbe_module);
    lib.linkLibC();
    lib.bundle_compiler_rt = (binding == .c or binding == .cpp);

    if (binding == .c or binding == .cpp or binding == .rust) {
        const header_install = b.addInstallFileWithDir(
            b.path("include/c/farbe.h"),
            .header,
            "farbe.h",
        );
        b.getInstallStep().dependOn(&header_install.step);
        lib.installHeader(b.path("include/c/farbe.h"), "farbe.h");
    }
}

fn fileExists(path: []const u8) bool {
    std.fs.cwd().access(path, .{}) catch return false;
    return true;
}

fn setupExample(
    b: *std.Build,
    name: []const u8,
    binding: Binding,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    lib: *std.Build.Step.Compile,
    farbe_module: *std.Build.Module,
) !?*std.Build.Step.Run {
    const example_dir = b.fmt("examples/{s}", .{name});
    if (!fileExists(example_dir)) return null;

    return switch (binding) {
        .zig => blk: {
            const source_path = b.fmt("examples/{s}/main.zig", .{name});
            if (!fileExists(source_path)) break :blk null;

            const example = b.addExecutable(.{
                .name = name,
                .root_source_file = b.path(source_path),
                .target = target,
                .optimize = optimize,
            });
            example.root_module.addImport("farbe", farbe_module);

            break :blk b.addRunArtifact(example);
        },
        .c, .cpp => blk: {
            const ext = if (binding == .cpp) "cpp" else "c";
            const source_path = b.fmt("examples/{s}/main.{s}", .{ name, ext });
            if (!fileExists(source_path)) break :blk null;

            const example = b.addExecutable(.{
                .name = name,
                .target = target,
                .optimize = optimize,
            });

            example.addCSourceFile(.{
                .file = b.path(source_path),
                .flags = &[_][]const u8{if (binding == .cpp) "-std=c++11" else "-std=c11"},
            });
            example.linkLibrary(lib);
            example.linkLibC();
            if (binding == .cpp) example.linkLibCpp();
            example.addIncludePath(b.path("include"));

            break :blk b.addRunArtifact(example);
        },
        .rust => blk: {
            const cargo_path = b.fmt("examples/{s}/Cargo.toml", .{name});
            if (!fileExists(cargo_path)) break :blk null;

            const cargo = b.addSystemCommand(&[_][]const u8{
                "cargo",
                "run",
                "--manifest-path",
                cargo_path,
                "--verbose",
            });
            cargo.step.dependOn(&lib.step);
            break :blk cargo;
        },
    };
}
