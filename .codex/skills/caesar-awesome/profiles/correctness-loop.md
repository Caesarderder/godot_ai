# Correctness loop

Use for build, lifecycle, state, interaction, save/restart, and regression claims.

## Contract

Define the player-visible behavior first, then identify the authoritative state
owner and public interaction route. Instantiate the real owner inside a dedicated
fixture; do not duplicate its logic and do not confuse “real shipping owner” with
“must repeatedly launch the production main scene.”

Author and validate the task-specific Test Scenario before collecting the
baseline or modifying the owner.

## Evidence order

1. import/compile/parse;
2. bounded boot;
3. focused domain or component assertion;
4. focused fixture interaction through the real shipping owner;
5. restart/save/load/lifecycle repetition;
6. one conditionally triggered whole-path integration pass.

Record exit codes and bind results to the tested revision. A test that only checks
file presence cannot prove runtime behavior.

## Maker–critic loop

- Maker receives one failing assertion or reproducible scenario.
- Deterministic verifier reruns the smallest relevant route.
- Critic is optional unless the expected behavior itself requires judgment.
- Freeze the passing interaction and lifecycle gates before expanding scope.

Reject fixes that bypass the shipping owner through test-only state mutation.

## Exit

Pass only when the outcome is observed through the declared public route, repeated
where idempotency matters, and integrated without breaking frozen gates.
