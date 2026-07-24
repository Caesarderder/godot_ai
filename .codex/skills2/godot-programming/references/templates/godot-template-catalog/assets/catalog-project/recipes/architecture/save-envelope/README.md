# Save envelope

Use this artifact only for the payload envelope. File paths, atomic replacement, backup retention,
migrations, size limits, and recovery behavior remain owned by `$save-load`.

Call `encode()` before serialization and `decode()` after parsing. Treat every `ok=false` result as an
explicit recovery path; never silently substitute fabricated player data.
