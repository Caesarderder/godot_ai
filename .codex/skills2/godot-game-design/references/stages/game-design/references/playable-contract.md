# Playable Contract Reference

Use this as a selection guide, not a mandatory template. Add only sections that reduce a real design
ambiguity for the selected first playable.

## Compact contract

```markdown
## Playable Contract

### Promise and proof moment
- Player promise:
- Observable proof:

### Core interaction loop
| Step | Player intent/input | Rule and world response | Feedback | Resulting state |
|---|---|---|---|---|

### State and outcomes
- Initial state:
- Success:
- Failure:
- Recovery:
- Restart:

### Systems and ownership
| System | Responsibility | Owns | Depends on | Explicitly does not own |
|---|---|---|---|---|

### Tuning contract
| Value | Unit/range | Relationship | Intended effect | Evidence for changing it |
|---|---|---|---|---|

### First-playable content
| Content | Gameplay purpose | Reuse or variation | Deferred follow-up |
|---|---|---|---|

### Acceptance evidence
| Behavior or hypothesis | Deterministic check | Human observation | Pass signal |
|---|---|---|---|
```

## Quality heuristics

### Prefer

- player-observable language;
- state transitions and ownership;
- ranges and relationships over decorative precision;
- one complete loop before multiple partial systems;
- content that teaches or varies a mechanic;
- falsifiable fun hypotheses;
- explicit restart and recovery behavior.

### Reject

- “feels good” without an event, timing cue, or observation;
- “balanced” without a comparison and player effect;
- mechanics that do not affect a decision or state;
- a list of features with no loop connection;
- UI requirements that do not identify information priority;
- acceptance criteria such as “works correctly”;
- technical architecture inserted to make the design appear complete.

## Example behavior check shapes

- Given the run is active, when the player performs the primary action within range, the target state
  changes once and the corresponding feedback begins within the same gameplay beat.
- When the failure condition is reached, gameplay input no longer mutates the run, the cause is
  communicated, and restart restores the documented initial state.
- A new player can identify the immediate goal and complete one loop without implementation guidance.

Adjust timing and observability to the game. Do not copy placeholder values into the product contract.
