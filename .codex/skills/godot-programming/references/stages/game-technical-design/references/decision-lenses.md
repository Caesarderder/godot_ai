# Technical Design Decision Lenses

Use lenses as review questions, not fictional job titles or delegation requirements. Apply only lenses relevant to the milestone.

## Product and game-design lens

- Does the technical slice preserve the core player fantasy and stated pillars?
- Can the player perform a meaningful choice or skillful action in this milestone?
- Are success, failure, feedback, and retry concrete enough to implement and observe?
- Is a “fun” claim labeled as a playtest hypothesis rather than assumed true?

## Production lens

- Is this the smallest increment that closes risk and creates player value?
- Are dependencies, non-goals, and rollback visible?
- Does content expansion wait for a proven loop?
- Is any milestone merely internal infrastructure with no observable acceptance path?

## Godot architecture lens

- Does the creator of a scene/node own its wiring and teardown?
- Is mutable state authoritative in one place?
- Are direct commands, local signals, and injected dependencies used at the narrowest lifetime?
- Are application-lifetime services genuinely required?

## GDScript and lifecycle lens

- Can typed contracts express public methods, signals, resources, and collections?
- Do awaited, deferred, timer, and tween paths re-check node/session lifetime?
- Are pause, scene replacement, retry, and repeated enter/exit considered?
- Does the design avoid per-frame searches, unbounded work, and unnecessary allocation without guessing performance problems?

## Web and Compatibility lens

- Does rendering stay within Compatibility support?
- Does logic remain correct without threads?
- Are browser resize, iframe/canvas coordinates, focus, touch/gamepad, audio startup, and persistence checked when relevant?
- Is a browser validation step present for behavior headless Godot cannot prove?

## QA and release lens

- Is each acceptance statement observable or testable?
- Are logic, scene integration, visual/feel, and Web behavior assigned appropriate evidence?
- Are corrupted data and failed dependencies handled, not merely logged?
- Are asset provenance, licenses, localization, accessibility, and release constraints included only when the milestone introduces them?

## Verdict

Conclude with one of:

- `READY`: implementation can start without inventing material product or architecture decisions.
- `READY WITH SPIKE`: implementation starts with the named bounded experiment.
- `NEEDS DECISION`: identify the single product or hard-to-reverse choice that blocks responsible implementation.

Do not reject a design for missing irrelevant paperwork.
