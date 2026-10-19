const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Each backend is optional. Without it, the backend is a stub with the
    // same API (`enabled` is false). MariaDB needs MariaDB Connector/C
    // (libmariadb): `apt install libmariadb-dev` (Debian, Raspberry Pi OS)
    // or `brew install mariadb-connector-c` (macOS). A package that
    // depends on this one gives the option as `.mariadb = false`.
    const mariadb = b.option(bool, "mariadb", "Include MariaDB support (default: true)") orelse true;

    const options = b.addOptions();
    options.addOption(bool, "mariadb", mariadb);

    const module = b.addModule("db", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "build_options", .module = options.createModule() },
        },
    });
    if (mariadb) {
        // The C API of MariaDB Connector/C, as the import "c" of the backend.
        const c = b.addTranslateC(.{
            .root_source_file = b.path("src/mariadb/c.h"),
            .target = target,
            .optimize = optimize,
        });
        c.linkSystemLibrary("libmariadb", .{});
        module.addImport("c", c.createModule());
        module.linkSystemLibrary("libmariadb", .{});
    }

    // The tests that need a database skip unless TEST_DATABASE_URL is set,
    // for example to a MariaDB server. They use temporary tables only. The
    // result depends on the database, and the cache key does not include
    // the environment, so the tests run each time.
    //
    //     TEST_DATABASE_URL=mariadb://... zig build test
    const tests = b.addTest(.{ .root_module = module });
    const run_tests = b.addRunArtifact(tests);
    run_tests.has_side_effects = true;
    const test_step = b.step("test", "Run tests (the database tests need TEST_DATABASE_URL)");
    test_step.dependOn(&run_tests.step);
}
