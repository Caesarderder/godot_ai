# Basic state machine

Use for objects with a small number of mutually exclusive states. Each state is a child Node with
explicit `enter()` and `exit()` hooks. Keep transition authority in the machine.

Use a state-chart plugin only when nested or parallel state semantics are genuinely required. This
recipe intentionally has no editor plugin dependency.
