//! Stub for builds without MariaDB support (`-Dmariadb=false`). It has the
//! same API, but a pool cannot be created. Thus an application can make the
//! database optional at build time without changes to its code.

const std = @import("std");
const common = @import("common.zig");

const Error = common.Error;

pub fn libraryInit() !void {}

pub fn libraryEnd() void {}

pub const Pool = struct {
    connection: common.Connection,
    options: common.Options,

    pub fn open(_: std.mem.Allocator, _: std.Io, _: []const u8, _: common.Options) error{DbNotSupported}!*Pool {
        return error.DbNotSupported;
    }

    pub fn create(_: std.mem.Allocator, _: std.Io, _: common.Connection, _: common.Options) error{DbNotSupported}!*Pool {
        return error.DbNotSupported;
    }

    pub fn destroy(_: *Pool) void {}

    pub fn acquire(_: *Pool) Error!*Conn {
        return error.DbNotConfigured;
    }
};

pub const Conn = struct {
    pub fn release(_: *Conn) void {}

    pub fn exec(_: *Conn, comptime _: []const u8, _: anytype) Error!common.ExecResult {
        return error.DbNotConfigured;
    }

    pub fn query(_: *Conn, comptime T: type, _: std.mem.Allocator, comptime _: []const u8, _: anytype) Error![]T {
        return error.DbNotConfigured;
    }

    pub fn one(_: *Conn, comptime T: type, _: std.mem.Allocator, comptime _: []const u8, _: anytype) Error!?T {
        return error.DbNotConfigured;
    }

    pub fn execScript(_: *Conn, _: []const u8) Error!void {
        return error.DbNotConfigured;
    }

    pub fn begin(_: *Conn) Error!void {
        return error.DbNotConfigured;
    }

    pub fn commit(_: *Conn) Error!void {
        return error.DbNotConfigured;
    }

    pub fn rollback(_: *Conn) void {}

    pub fn savepoint(_: *Conn) Error!common.Savepoint {
        return error.DbNotConfigured;
    }

    pub fn rollbackTo(_: *Conn, _: common.Savepoint) Error!void {
        return error.DbNotConfigured;
    }

    pub fn releaseSavepoint(_: *Conn, _: common.Savepoint) Error!void {
        return error.DbNotConfigured;
    }
};
