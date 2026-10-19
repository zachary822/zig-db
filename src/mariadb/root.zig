//! The MariaDB backend: a connection pool and typed queries on top of
//! MariaDB Connector/C. MySQL servers also work, with the same client
//! library.
//!
//!     try db.mariadb.libraryInit();
//!     defer db.mariadb.libraryEnd();
//!     const pool = try db.mariadb.Pool.open(gpa, io, "mariadb://app:pw@127.0.0.1/app", .{});
//!     defer pool.destroy();
//!
//!     const conn = try pool.acquire();
//!     defer conn.release();
//!     const users = try conn.query(struct { id: u64, name: []const u8 }, arena,
//!         \\SELECT id, name FROM user WHERE id > ?
//!     , .{10});
//!
//! Builds without MariaDB support (`-Dmariadb=false`) use a stub with the
//! same API, so the code of the application does not change.

const build_options = @import("build_options");
const common = @import("common.zig");
const impl = if (build_options.mariadb) @import("pool.zig") else @import("disabled.zig");

/// True when this build includes MariaDB support.
pub const enabled = build_options.mariadb;

pub const Connection = common.Connection;
pub const Tls = common.Tls;
pub const Options = common.Options;
pub const Error = common.Error;
pub const ExecResult = common.ExecResult;
pub const Binary = common.Binary;
pub const binary = common.binary;
pub const UrlError = common.UrlError;
pub const parseUrl = common.parseUrl;
pub const Pool = impl.Pool;
pub const Conn = impl.Conn;

/// Call one time at startup, before other threads start.
pub const libraryInit = impl.libraryInit;
/// Call one time at shutdown, after all connections are closed.
pub const libraryEnd = impl.libraryEnd;

test {
    _ = common;
    _ = impl;
}
