# Scene contract

Use when a reusable scene must fail fast if required nodes, signals, Resource properties, or InputMap
actions are missing. Keep the contract next to the scene and run it through the project's chosen test
framework.

This dependency-free example can run before GUT or gdUnit4 is installed. `$godot-testing` decides the
real project's framework and command.
