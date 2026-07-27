# Godot First-Playable Verification

Use the repository's documented commands and configured Godot binary first. These are fallback command
shapes for Godot 4.6; adjust the executable and preset name from current project evidence.

## Contents

- [Confirm environment](#1-confirm-environment)
- [Import and parse](#2-import-and-parse)
- [Bounded main-scene start](#3-bounded-main-scene-start)
- [Exercise the scene lifecycle](#4-exercise-the-scene-lifecycle)
- [Run project tests](#5-run-project-tests)
- [Export Web release](#6-export-web-release)
- [Browser evidence](#7-browser-evidence)
- [Evidence report](#evidence-report)

## 1. Confirm environment

```bash
godot --version
```

Require the repository's supported 4.6.x line. Record the exact version.

## 2. Import and parse

```bash
godot --headless --path . --import
```

The command imports resources and exits. Preserve output and exit code. Missing resources, parse
errors, invalid project settings, or import failures block engine completion.

## 3. Bounded main-scene start

```bash
godot --headless --path . --quit-after 3
```

This proves only that the configured main scene starts and survives a bounded run. It does not prove
real input, visuals, audio, browser lifecycle, or fun. Add focused tests or a deterministic debug
driver for rule and restart behavior when practical.

## 4. Exercise the scene lifecycle

Obtain one of these current evidence forms:

1. an interactive Godot run that records the operator reaching success, failure, and restart; or
2. a scene-level integration driver that loads the real main/gameplay scene, exercises semantic input
   or the same public entry points, observes the world and feedback state, reaches both outcomes, and
   verifies restart returns all owned state to its initial contract.

Record the scene/build revision and the exact path observed. A boot smoke, static review, isolated
rule unit test, or screenshot does not exercise the playable loop.

## 5. Run project tests

Use the existing repository command. Record runner, exit code, passed/failed count, and first failure.
Never install a test addon as a side effect of prototype verification.

## 6. Export Web release

Prefer the repository's Builda build route. Builda copies the project into an isolated snapshot and
writes its own platform-controlled Web preset and template without changing the workspace preset.
Capture the Builda build identifier, runtime/template identity, generated snapshot preset evidence,
artifact manifest, and logs. For this controlled path, the generated snapshot preset—not the user's
workspace `export_presets.cfg`—is authoritative and must contain:

```ini
variant/thread_support=false
```

Cross-check that the output contains the expected HTML and game payload and no unexpected worker
artifact. Do not edit the workspace preset merely to satisfy a Builda-controlled build.

Only for an explicitly requested external or local export, inspect the workspace
`export_presets.cfg`, use its exact existing Web preset name, and require the same no-thread setting.
Use the project's existing export command; if none exists, report the missing local export contract
instead of inventing one. Treat that local preset as external evidence, not proof of a
Builda-controlled release.

## 7. Browser evidence

Use the repository's Builda preview/build route when present. Otherwise serve the exported directory
from a local HTTP origin and inspect it with an available browser tool. At minimum check:

- load completes without a loader, script, or unhandled runtime error;
- keyboard, pointer, gamepad, or touch input required by the contract reaches the game;
- the player can reach success and failure and restart;
- layout remains usable at the target and one narrower viewport;
- audio unlock behavior is clear when audio is part of critical feedback;
- no unsupported threaded runtime artifact is present.

Record the URL scope, browser, build source, observed path, and result. A screenshot alone does not
prove interaction.

## Evidence report

```markdown
## Prototype Evidence

| Surface | Command or observation | Result | Evidence/artifact | Gap |
|---|---|---|---|---|
| Godot version | ... | PASS/FAIL | ... | ... |
| Import | ... | PASS/FAIL | ... | ... |
| Main-scene start | ... | PASS/FAIL | ... | ... |
| Scene loop execution | ... | PASS/FAIL/NOT RUN | ... | ... |
| Deterministic checks | ... | PASS/FAIL/NOT RUN | ... | ... |
| Web export | ... | PASS/FAIL/NOT RUN | ... | ... |
| Browser loop | ... | PASS/FAIL/NOT RUN | ... | ... |
| Human playtest | ... | OBSERVED/NOT RUN | ... | ... |
```

Never collapse `NOT RUN` into `PASS WITH WARNINGS`. State the strongest supported outcome: static,
engine-verified, Web-verified, or human-observed.
