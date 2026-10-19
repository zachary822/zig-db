//! Optional spans for tracing (for example OpenTelemetry). The library has
//! no tracing of its own: the application gives a tracer as the declaration
//! `zig_db_tracer` in its root source file, in the same way as `std_options`:
//!
//!     pub const zig_db_tracer = struct {
//!         pub fn start(name: []const u8, kind: db.SpanKind) MySpan { ... }
//!     };
//!
//! `start` is called on the thread that does the operation, and the span
//! ends on the same thread. The span type must have these methods:
//!
//!     pub fn set(span: *MySpan, key: []const u8, value: anytype) void; // a string or an integer
//!     pub fn fail(span: *MySpan, message: []const u8) void;            // an error name
//!     pub fn end(span: *MySpan) void;
//!
//! The strings stay valid until `end`. Without `zig_db_tracer`, the spans
//! do nothing.
//!
//! The spans: `db.pool.acquire` (internal) for `Pool.acquire`, and a client
//! span for each `exec` and `query`, with the name of the operation (for
//! example `SELECT`) and the attributes `db.system.name`,
//! `db.operation.name`, `db.query.text`, and `db.response.affected_rows`
//! or `db.response.returned_rows`.

const root = @import("root");

pub const SpanKind = enum { internal, client };

const Tracer = if (@hasDecl(root, "zig_db_tracer")) root.zig_db_tracer else Noop;

pub const Span = @typeInfo(@TypeOf(Tracer.start)).@"fn".return_type.?;

pub fn start(name: []const u8, kind: SpanKind) Span {
    return Tracer.start(name, kind);
}

const Noop = struct {
    const NoopSpan = struct {
        pub fn set(_: *NoopSpan, _: []const u8, _: anytype) void {}
        pub fn fail(_: *NoopSpan, _: []const u8) void {}
        pub fn end(_: *NoopSpan) void {}
    };

    fn start(_: []const u8, _: SpanKind) NoopSpan {
        return .{};
    }
};
