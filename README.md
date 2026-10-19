# zig-db

Database clients for Zig 0.17, each with a connection pool. Give a
connection string, and get a pool of connections with typed queries.

Backends:

- `mariadb`: MariaDB (and MySQL), with MariaDB Connector/C.

## Install

Add the dependency to `build.zig.zon`. A path works for a local copy:

```zig
.zig_db = .{ .path = "../zig-db" },
```

Then import the module in `build.zig`:

```zig
const zig_db = b.dependency("zig_db", .{
    .target = target,
    .optimize = optimize,
    // Optional. With false, the backend is a stub with the same API.
    .mariadb = true,
});
exe.root_module.addImport("db", zig_db.module("db"));
```

The MariaDB backend needs libmariadb and pkg-config:
`apt install libmariadb-dev` (Debian) or `brew install mariadb-connector-c`
(macOS).

## Use

```zig
const db = @import("db");
const mariadb = db.mariadb;

// One time, before other threads start.
try mariadb.libraryInit();
defer mariadb.libraryEnd();

const pool = try mariadb.Pool.open(gpa, io, "mariadb://app:secret@127.0.0.1:3306/app", .{
    .pool_size = 8,
    .acquire_timeout_ms = 5000,
});
defer pool.destroy();

const conn = try pool.acquire();
defer conn.release();

const User = struct { id: u64, name: []const u8, email: ?[]const u8 };
const users = try conn.query(User, arena,
    \\SELECT id, name, email FROM user WHERE id > ?
, .{10});

const result = try conn.exec(
    \\UPDATE user SET name = ? WHERE id = ?
, .{ "Ann", 1 });
_ = result.affected_rows;
```

### The connection string

```
mariadb://USER[:PASSWORD]@[HOST][:PORT]/DATABASE[?PARAM=VALUE&...]
```

`mysql://` is also accepted. HOST is 127.0.0.1 and PORT is 3306 by default.
Percent-encode special characters, for example `@` as `%40`. Parameters:

- `socket=PATH`: use a Unix socket in place of TCP.
- `tls=required|disabled`: TLS for TCP (default: required, with
  verification of the server certificate).
- `tls_ca=PATH`: a CA certificate file for the verification.

To examine the parts before you make a pool, use `mariadb.parseUrl`. Then
give the result to `mariadb.Pool.create`.

### The pool

- The pool opens a connection only when it is necessary. Thus `open`
  works when the database is not available, and requests work again when
  it is back.
- `acquire` waits up to `acquire_timeout_ms` for a free connection.
- A connection that was idle for 30 s gets a ping before it is used. A
  connection older than `conn_max_age_s` (default 3600) opens again.
- Each connection keeps its prepared statements. The SQL is comptime, so
  each query is prepared one time for each connection.
- Each connection uses utf8mb4 and UTC (`time_zone = '+00:00'`).

### Queries

- `exec(sql, args)`: a statement without rows. It returns `affected_rows`
  and `insert_id`.
- `query(T, arena, sql, args)`: all rows as `[]T`. `T` is a struct with one
  field for each column, in order.
- `one(T, arena, sql, args)`: the first row, or null.
- `begin`, `commit`, `rollback`: transactions. After a failed statement in
  a transaction, all statements fail until `rollback`.
- `savepoint`, `rollbackTo`, `releaseSavepoint`: savepoints in a
  transaction from `begin`. `rollbackTo` undoes only the changes after the
  savepoint. After a failed statement, it also lets the transaction
  continue. If the server undid the full transaction (for example after a
  deadlock), `rollbackTo` fails, and only `rollback` is possible.

```zig
try conn.begin();
errdefer conn.rollback();
_ = try conn.exec(
    \\INSERT INTO order (id) VALUES (?)
, .{1});
const sp = try conn.savepoint();
if (conn.exec(
    \\INSERT INTO audit (order_id) VALUES (?)
, .{1})) |_| {} else |_| try conn.rollbackTo(sp); // keep the order
try conn.commit();
```
- `execScript(sql)`: several statements without parameters. The pool must
  have `multi_statements = true`. Use it only for trusted SQL.

The types for parameters and fields: integers, floats, `bool`, enums (as
their names), `[]const u8` (text), `db.Binary` (bytes, make one with
`db.binary`), `[N]u8` (a binary result of exactly N bytes), and optionals
for NULL.

## Tracing (optional)

The library makes no spans of its own. To get a span for each `acquire`,
`exec` and `query`, declare `zig_db_tracer` in the root source file of your
program. See `src/tracing.zig` for the interface.

```zig
pub const zig_db_tracer = struct {
    pub fn start(name: []const u8, kind: db.SpanKind) MySpan { ... }
};
```

## Tests

```sh
zig build test
TEST_DATABASE_URL=mariadb://user:pw@127.0.0.1/test zig build test
zig build test -Dmariadb=false
```

The database tests use temporary tables only. Without
`TEST_DATABASE_URL`, they skip.
