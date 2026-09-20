# Concurrency tests

> [Back to the test index](README.md)

`TRickSQLConcurrencyTests` contains five scenarios in the official project. Each thread creates its own RickSQL operation/FireDAC session; the framework connection is not shared across threads.

The final scenarios cover independent SQLite databases, conditional SQLite+PostgreSQL execution, repeated concurrent readers on one SQLite file, deterministic SQLite write contention (`SQLITE_BUSY`) followed by successful recovery after lock release, and isolation between simultaneous success/failure operations.

The legacy expectation that repeated SQLite read/write operations must always both succeed was replaced because it proved timing-dependent and legitimately produced `SQLITE_BUSY`/`SQLITE_BUSY_RECOVERY`. No automatic retry, global mutex, or production change was introduced merely to make the test green. No global thread-safety claim is made beyond the exercised contracts.
