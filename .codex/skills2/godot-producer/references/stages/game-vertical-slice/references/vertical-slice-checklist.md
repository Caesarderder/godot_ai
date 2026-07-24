# Vertical Slice Readiness Checklist

## Complete experience

- [ ] Launch reaches a readable first state without developer intervention.
- [ ] A new player can discover the first meaningful action.
- [ ] The core loop includes choice, consequence, feedback, and reward.
- [ ] Content introduces, varies, escalates, and resolves within the slice.
- [ ] Success, failure, retry/recovery, pause, and quit paths work.
- [ ] The end communicates what was achieved and why another session is appealing.

## Representative quality

- [ ] Critical actions have coherent visual, animation, camera, VFX, and audio feedback.
- [ ] HUD exposes the information needed for decisions without placeholder behavior.
- [ ] Menus and settings match the slice's intended quality, not only gameplay scenes.
- [ ] Included art and audio use the intended production pipeline and legal source records.
- [ ] Performance budgets are explicit and measured in the target Web runtime.

## Continuity and resilience

- [ ] Settings persist across reload when browser storage is available.
- [ ] Required progress save/load and migration paths work, or are explicitly out of scope.
- [ ] Storage failure or non-persistence is surfaced without corrupting runtime state.
- [ ] Resize, focus loss, tab suspension, audio unlock, and return-to-game behavior work.
- [ ] Required mouse, keyboard, and applicable gamepad paths are complete.
- [ ] Focus visibility, non-color cues, readable text, reduced motion, and critical audio alternatives are verified where required.

## Evidence

- [ ] Automated tests ran with command, exit code, and result recorded.
- [ ] Headless import and targeted scene smoke ran successfully.
- [ ] A fresh single-threaded Web build was exercised in a browser.
- [ ] Both success and failure paths were played end to end.
- [ ] Runtime errors, warnings, and performance observations were captured.
- [ ] A no-guidance playtest ran and observations are linked, or the gate is `BLOCKED`.
- [ ] The verdict distinguishes evidence, inference, and `NOT RUN` items.
