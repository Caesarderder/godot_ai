# First Playable Definition

Use this checklist to reduce a product contract to one complete implementation slice.

## Slice card

```markdown
- Player promise being tested:
- Immediate goal:
- Primary input:
- Meaningful choice or skill:
- World response:
- Critical feedback:
- Success condition:
- Failure condition:
- Restart action:
- Reason to retry:
- Explicitly deferred:
```

## Selection test

The slice is small enough when:

- it has one main verb or tightly coupled verb set;
- one scene or short scene sequence can demonstrate the full loop;
- success and failure arise from the same core rules;
- restart is part of the lifecycle rather than an editor rerun;
- one player session can test the stated fun hypothesis;
- removing another system would break comprehension or the player promise.

If a proposed system does not pass the last test, defer it.

## Implementation invariants

- Gameplay reads semantic actions, not physical keys in rule code.
- One owner controls run state and outcome transitions.
- Mutable state has a clear reset path.
- Signals are not connected repeatedly on restart.
- Bounded async work cannot mutate a replaced run.
- UI reports gameplay state but does not secretly own gameplay rules.
- Feedback is triggered by the authoritative state change.
- The first frame, success screen, failure screen, and restarted state remain valid at the target
  viewport and at one narrower browser viewport.

## Nontraditional outcomes

For toys, sandboxes, contemplative games, or creative tools, map the lifecycle explicitly:

- success equivalent: a completed expression, discovered state, or bounded session goal;
- failure equivalent: interruption, invalid state, exhausted resource, or intentional reset point;
- restart equivalent: begin another clean attempt without stale state.

Do not omit lifecycle handling simply because the experience has no score screen.
