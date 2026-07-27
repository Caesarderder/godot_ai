# Damage pipeline

Use for local hit detection where the attacker supplies immutable damage data and the receiver owns
health. Collision filtering and once-per-attack behavior must be added at the hitbox boundary for the
specific game.

HUD and effects observe the health signals; they never mutate health directly.
