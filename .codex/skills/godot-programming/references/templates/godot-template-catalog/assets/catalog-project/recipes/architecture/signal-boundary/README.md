# Signal boundary

Use when a child component should report intent without mutating its parent or a global singleton.
The mediator owns state and connects/disconnects within the scene lifetime.

Avoid a global EventBus for events that stay inside one feature scene.
