# Level Contract Reference

## Minimal structure

1. Level promise and place in the wider game.
2. Entry knowledge/state and exit knowledge/state.
3. Critical path, optional branches, gates, checkpoints, and recovery.
4. Teaching sequence and encounter purposes.
5. Wayfinding and accessibility cues.
6. Graybox boundary and acceptance scenarios.
7. Evidence, open questions, and next experiment.

## Flow table

| Beat | Entry state | Player decision/action | World response | Feedback | Exit/gate | Failure recovery |
| --- | --- | --- | --- | --- | --- | --- |

Keep beats observable. A label such as “combat room” is incomplete without its purpose, choices, completion rule, and reset behavior.

## Encounter grammar

For each encounter record:

- purpose in learning, mastery, pacing, story, or resource pressure;
- available player capabilities and meaningful choices;
- spatial affordances, hazards, enemy or puzzle roles, and escalation;
- success, failure, reset, and checkpoint state;
- tuning variables and the observation that would justify changing them.

## Failure checklist

- Required clue, resource, or ability is only on an optional path.
- One-way transition can occur before its prerequisite is satisfied.
- Trigger cannot recover after interruption, death, reload, or backtracking.
- Shortcut bypasses state ownership rather than only space.
- Landmark or objective cue is hidden from the likely approach angle.
- Color is the only distinction for a critical state.
- Camera, collision, or navigation makes an intended route technically reachable but practically unusable.
- Encounter reset duplicates, loses, or permanently locks state.

## Evidence levels

- **Documented:** topology and behavior are described only.
- **Grayboxed:** current project scenes implement the intended topology and rules.
- **Flow exercised:** named paths and recovery cases ran on the target runtime.
- **Player observed:** an uncoached player produced relevant comprehension or pacing evidence.
- **Web verified:** the current exported artifact completed the applicable path in a real browser.

Never promote one evidence level into another.
