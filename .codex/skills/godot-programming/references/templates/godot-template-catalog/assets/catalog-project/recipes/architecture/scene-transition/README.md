# Scene transition

Use for a feature-owned scene host that must replace one child and report deterministic success or
failure. Promote the router to an Autoload only when the application truly requires cross-scene
lifetime ownership.

This minimal recipe does not implement background loading. Add it only after profiling proves that
synchronous loading is a user-visible problem.
