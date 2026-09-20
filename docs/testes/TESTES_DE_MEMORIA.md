# Lifecycle, ownership, and memory

> [Back to the test index](README.md)

The final suite has no separate `tests/memoria` folder. Lifecycle/ownership contracts were consolidated into the classes that exercise the actual responsibility: fluent dataset ownership, materialized dataset lifetime, FireDAC session/connection/query lifecycle, driver-link/context ownership, and transaction cleanup/diagnostics.

These are functional lifecycle validations. **No memory-leak detector was run in this task.** Therefore the project is not claimed to be leak-free.
