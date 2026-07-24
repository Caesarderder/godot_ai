# Interaction

Use when several nearby targets can compete for one player interaction. Detection is deliberately
outside this recipe: Area, ray, cursor, and accessibility scans can all add/remove candidates through
the same boundary.

The interactor owns deterministic priority selection. UI observes `selection_changed`; it does not
decide which gameplay target executes.
