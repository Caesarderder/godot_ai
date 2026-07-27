# Feature slice

Use when a capability should own its scene, controller, configuration, and focused test together.
Avoid turning this layout into a mandatory global folder hierarchy.

Copy `counter_config.gd`, `counter_feature.gd`, and `counter_feature.tscn` into one feature directory,
then rename the `Template*` classes. Keep configuration immutable at runtime and expose state changes
through typed signals.

Catalog verification (includes this recipe's focused contract test):

```bash
godot --headless --path <catalog-project> --script res://tests/run_all.gd
```

In a normal project, port the focused test to the framework already selected through `$godot-testing`.
