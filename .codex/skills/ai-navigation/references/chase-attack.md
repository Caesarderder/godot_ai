# Chase and Attack Routing

`ai-navigation` owns only the movement side of chase behavior:

1. Receive a selected target from the decision layer.
2. Throttle updates to `NavigationAgent2D.target_position`.
3. Stop path movement when the decision layer enters attack range.
4. Report arrival, unreachable paths, or target loss back to the decision layer.

Use **state-machine** for patrol/chase/attack transitions, entry and exit lifecycle, cooldown ownership, and interruption rules. Do not duplicate an FSM implementation here.
