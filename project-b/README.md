# Nightglass: Blacksite

An original Godot FPS first-playable built as an isolated `project-b/` experiment.

Controls: WASD move, mouse look, left mouse fire, Shift sprint, Space jump, R reload, Escape release pointer, Enter restart after an outcome.

The slice proves one complete loop: enter the blacksite, eliminate four sentries, survive return fire, reach victory or defeat, and redeploy into a clean state. It uses original Godot-authored geometry and does not include or claim parity with proprietary Call of Duty content.

Verification:

```bash
godot --headless --path project-b --import
godot --headless --path project-b --quit-after 180
godot --headless --path project-b -s tests/run_fps_vertical_slice_tests.gd
godot --path project-b -s tools/capture_fps_review.gd
```
