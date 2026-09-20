# Unit and contract tests

> [Back to the test index](README.md)

Unit/contract tests are part of the same official DUnit project; there is no separate runner. Main groups cover error normalization, validators and SQL dialects, transaction-state handling, client libraries/VendorLib, driver factory/contracts, models, FireDAC services, materialization, and fluent facade lifecycle.

These tests do not replace functional integration where FireDAC side effects are observable, so local SQLite, concurrency, and environment-conditional integration scenarios remain separate categories inside the same suite.
