//! Database clients with connection pools. Each backend is a namespace with
//! the same shape: `Pool` (`open` with a connection string, `acquire`,
//! `destroy`) and `Conn` (`exec`, `query`, `one`, `begin`, `commit`,
//! `rollback`, `savepoint`, `rollbackTo`, `releaseSavepoint`, `release`).
//! The backends:
//!
//! - `mariadb`: MariaDB and MySQL, with MariaDB Connector/C.
//!
//! To add a backend, add a directory `src/NAME/` with a `root.zig`, export it
//! here, and add a build option for it in build.zig.

const common = @import("common.zig");
const tracing = @import("tracing.zig");

pub const mariadb = @import("mariadb/root.zig");

pub const Error = common.Error;
pub const ExecResult = common.ExecResult;
pub const Binary = common.Binary;
pub const binary = common.binary;

/// The kind of a span, for the tracer of the application (see `tracing.zig`).
pub const SpanKind = tracing.SpanKind;

test {
    _ = common;
    _ = mariadb;
}
