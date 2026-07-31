# Game-feel loop

Use for input response, locomotion, camera, weapon/action impact, damage feedback,
recovery, and other time-dependent player control claims.

## Response-chain contract

Express the action as observable links:

`input → accepted intent → pose/motion → camera/VFX/audio response → consequence → recovery`

Name timings or events that can be measured without prescribing arbitrary values.
Inspect the intended target device and control method.

Author a scenario that scripts the decisive input and observation windows before
changing the response chain. Do not replace it with manual play and a selected
video moment.

For a weapon or action, prefer one parameterized fixture run that sequences
fire, sustained fire, partial reload, empty/dry-fire, recovery, multiple
directions, and canonical player/side/rear/muzzle/target views. Emit synchronized
state, timing, video/contact-sheet, audio/VFX, and assertion artifacts for the
critic. Register a new compatible weapon through the subject parameter instead
of cloning the fixture.

## Evidence

Collect:

- timestamped input and state events where feasible;
- frame sequence or video from the player camera;
- animation/action timing;
- camera displacement and recovery behavior;
- synchronized VFX/audio/consequence;
- repeated target-player observation for subjective feel.

A still image cannot close a feel gate. Automated timing can prove latency or
sequence, but not that the result feels good.

## Maker–critic loop

Keep input, camera, motion, animation timing, impact effects, and audio together
when they form one response chain. Change one bounded hypothesis, replay the named
scenario, and compare time-series evidence. Protect correctness and accessibility
gates throughout.

Use model critique to identify visible timing/readability gaps. Use target-player
observation to close required feel claims.

## Exit

Pass measurable response assertions and record human evidence separately. If no
target player or device is available, finish the experiential gate as
`human_required` or `capability_unavailable`.
