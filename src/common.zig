//! Types that all backends share.

pub const Error = error{
    /// No database: the build has no support for the backend (the
    /// disabled stub), or the application has no database configured.
    DbNotConfigured,
    /// The database server cannot be reached.
    DbUnavailable,
    /// All connections stayed in use for `acquire_timeout_ms`.
    PoolTimeout,
    /// The task was canceled (`std.Io` cancelation) while it waited for a
    /// free connection.
    Canceled,
    /// The database rejected the query, or the result does not match the
    /// requested type. The details are logged.
    QueryFailed,
    OutOfMemory,
};

/// Binary data (BINARY, VARBINARY, BLOB columns). As a query parameter, it
/// is sent as bytes, without a character set; a plain `[]const u8` is sent
/// as utf8mb4 text. Make one with `binary`. As a result field, it holds the
/// bytes of the column.
pub const Binary = struct {
    bytes: []const u8,
};

/// Marks `bytes` as binary data for a query parameter.
pub fn binary(bytes: []const u8) Binary {
    return .{ .bytes = bytes };
}

pub const ExecResult = struct {
    affected_rows: u64,
    insert_id: u64,
};
