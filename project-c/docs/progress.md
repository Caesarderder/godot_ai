# Caesar Loop progress

## Contract

- Player outcome: read an original lane, fire Q, evade with E, and decide whether to push with a minion wave in 45 seconds.
- Quality bar: `artifacts/lane-action-review.png` at fixed 1280×720; critics inspect this file and the running scene directly.
- Baseline: project did not exist before this loop. Existing `project-a` and dirty `project-b/project.godot` are out of scope.

## Wave 1 — vertical slice

- Coupled / serialized: composition root, input, camera-space presentation, HUD and lane simulation.
- Independent surfaces: match state, ability cooldown contract, test/capture drivers.
- Evidence collected:
  - `godot --headless --path project-c --quit-after 2` booted on Godot 4.7.1.
  - `tests/run_moba_vertical_slice_tests.gd` printed `MOBA_VERTICAL_SLICE_TESTS_OK` (input, skill cooldown/consequence, reposition, win and clean restart).
  - `tools/capture_moba_review.gd` emitted `artifacts/lane-action-review.png` from a rendered Metal/GL Compatibility session.
- `tools/profile_moba_stress.gd` recorded a headless smoke sample: p50 6.847 ms, p95 10.218 ms, p99 15.003 ms, worst 34.675 ms across 180 frames.
- Final fresh static-artifact critique: **pass, 0.84 confidence**. Direct evidence: the final fixed capture explicitly shows `YOU`, `RIVAL`, both relays, enemy trajectory/arrow and `INCOMING`, `YOU HP 62/100`, Q/E values, timer, and `OBJECTIVE: DISABLE ENEMY RELAY`.
- Evidence pending: fresh artifact critique, real-play profiling with memory/object attribution and repeated runs, target-player session.

## Known limits

- This is a single-player local prototype, not an online MOBA.
- No claim of League of Legends equivalence, release readiness, visual parity, or fun is made.
- Capture is a fixed review pose; it is not a frame-time profile or player study.
- The headless stress numbers are smoke telemetry only, not target-device performance evidence.
- Highest next visual gap: the opposing unit clusters are not explicitly labelled `ALLY WAVE` / `ENEMY WAVE`; this is not a proof of first-time player understanding.

## Rejected review state

- Fresh artifact critique of the first capture: **fail**. Direct evidence: enemy danger was only conveyed by faint diagonal lines, so source, path and immediate player risk were not legible. This is preserved to prevent treating the initial capture as passing evidence.
- Next bounded revision: render a high-contrast, live enemy trajectory plus a target-area warning in the action review scenario; repeat the fixed capture and fresh critique.

## Wave 2 — three-lane match kernel

- Adds `features/match/three_lane_match.gd`: three lanes, two relay cores, outer towers, wave pressure and deterministic core victory. It is a headless domain kernel until the next integration step renders and controls it.
- Integrates `Pulse Lens` through the catalog quote into authoritative gold, a three-slot inventory and real Arc Strike damage; the arena HUD projects inventory count and bonus without recalculating rules.
- First three-lane inventory capture critique: **fail, 0.90 confidence**. Shapes exposed side color but not semantic roles. The selected lane now labels ally/enemy towers, heroes and minion waves, and widens HP text; this revision requires a fresh capture and critic.
- Revised role-labelled capture critique: **provisional pass, 0.82 confidence**. Remaining gap was ambiguous `LENS 1/3 · +12 ARC` wording; HUD now states purchased count and `ARC STRIKE DAMAGE +12` explicitly. Timed first-player evidence remains outstanding.
- Final inventory HUD critique: **pass, 0.98 confidence**. `GOLD 150`, `1 PURCHASED`, and `ARC STRIKE DAMAGE +12` are explicit and unclipped while selected-lane roles remain readable. Largest remaining visual gap is overlapping ID/HP text when multiple heroes share a lane; runtime input and alternate resolutions remain unverified.

## Wave 3 — hero combat lifecycle

- Fixes a real frame-rate defect: bot DPS now accumulates as floating-point damage instead of truncating every 60 FPS frame to zero.
- Adds deterministic hero death, 120-gold kill reward, eight-second respawn, short spawn protection, kill/event HUD projection, and distinct same-lane formation slots.
- Domain lifecycle assertions and `THREE_LANE_INTERACTION_TESTS_OK` now cover production W/S/F/Q/E/R inputs, enhanced damage, selected-lane pressure, recovery and clean reset. Revised action capture, fresh visual critic, alternate resolutions and target-player observation remain outstanding.
- First lifecycle capture critique: **fail, 0.82 confidence**. Kill score, reward and collision-free formation passed, but `K01 7.9s` required inference. Dead markers now state `[hero] DEAD` and `RESPAWN [time]` explicitly; fresh review remains required.
- Revised lifecycle capture critique: **pass, 0.86 confidence**. Same-lane formation, kill score, +120 gold, explicit death and respawn countdown were all readable; countdown contrast and timed player observation remain open.

## Wave 4 — original hero identity and growth

- Replaces D/K placeholders with five original archetypes (`Aerion`, `Vesper`, `Mira`, `Orun`, `Sable`), stable lane assignments, roles, signatures and authored attack values.
- A killer now receives XP, personal kill credit and deterministic level-up growth (+10 max HP, +3 attack). Bot DPS derives from living heroes' real attack values.
- Required evidence: domain progression tests, revised capture/critic, balance scan and target-player comprehension.
- First hero-identity critique: **fail, 0.97 confidence** because identity depended entirely on labels and controlled Vesper had no field marker. Five persistent vector emblems plus a controlled selection ring/chevron and a hero key are now implemented; label-hidden capture and fresh critique are required.
- One silhouette re-critique was **rejected as contradicted by the artifact**: it reported the controlled headline as truncated, but the original 1280×720 PNG visibly contains the complete `CONTROLLED · Vesper · Skirmisher · LEVEL 1 · XP 0 · Rift Step`, and `show_hero_labels` gates only field labels in code. A different fresh critic must decide the silhouette gate.
- Final silhouette re-critique: **pass, 0.97 confidence**. It verified all five geometry identities on both teams, Vesper's gold selection ring/triangle, complete controlled HUD, collision-free restored labels, and the kill/death read. A sequential lane-switch/death/respawn capture is the next persistence proof.
- First sequence critique: **fail, 0.97 confidence**. State continuity passed (`500→620` gold, `1—0`, death/countdown, redeploy/full HP), but the above-ring selection caret collided with the controlled HUD on TOP and the HP label on MID. The caret is now placed below the ring in the reserved gap; fresh sequence review is required.
- Revised sequence critique: **pass, 0.94 confidence**. TOP→MID selection, identity, kill/gold, death and redeploy were coherent with no important collisions. It requested an intermediate countdown frame; the sequence now records ready, 7.9s dead, ~3.9s dead, and redeployed states.
- Four-state countdown critique: **pass, 0.96 confidence**. It verified 7.9s→3.9s→HP100 with stable gold, kills and selection; uninterrupted continuity remained unproven. A deterministic same-session 91-frame/9-second capture now owns that evidence route and is encoded separately as review media.
- First animation audit: **fail, 0.98 confidence**. Disabling `_process` before tree entry did not hold, so wall-clock `_process(delta)` advanced the countdown in addition to fixed ticks. Capture now disables the scene after tree entry, asserts every 0.1s state, snaps respawn epsilon, and writes instance/script-hash/state provenance to `artifacts/respawn-continuity.csv`.
- Deterministic animation re-audit: **pass, 0.96 confidence**. It verified matching script hash, one arena instance, 91 exact 0.1s samples from 0.0–9.0, 8.0→0.1 countdown, HP100 at frame 80, protection through frame 87, subsequent legal damage, and stable 1 kill/620 gold.
- The bounded evidence enhancement is now implemented and recaptured: `respawn-continuity.csv` records `spawn_protection` directly (`0.75` at frame 80, `0.05` at frame 87, `0.00` at frame 88), while HP remains 100 until protection expires. Target-player readability evidence remains outstanding.

## Wave 5 — selectable five-hero signature kits

- `Tab` now cycles every Dawn hero and follows that hero's authored lane; existing `W`/`S` lane selection remains compatible and selects the lane's first Dawn hero.
- The match kernel owns slot-addressable selection and casting. Legacy `player_cast(lane)` delegates to that API, so prior callers keep working.
- Q has five distinct authoritative outcomes: Aerion absorbs damage with Solar Guard shield, Vesper deals single-target Rift Step damage, Mira damages every living lane target with Comet Array, Orun heals both living lane allies with Anchor Field, and Sable deals the roster's highest single-target base damage with explicit long-range semantics.
- The arena projects the controlled hero, signature result, effect amount/target count and shield state. Domain tests cover every kit; production-input tests cover hero cycling, W/S compatibility, area damage, HUD result state and reset.
- First independent kit review: **fail, 0.95 confidence**. Effective and zero-effect Q results both granted lane pressure, no cooldown existed, and hero selection retained stale ability HUD state. That allowed capped Aerion or full-health Orun to spam pressure and bypass the intended lane contest.
- The bounded fix adds per-hero two-second cooldowns, explicit `pressure_delta`, `NO_EFFECT` for capped shield/full-health healing, and result clearing on W/S/Tab selection. Domain tests now cover death, no target, spawn protection, shield cap/absorption, full-health healing and cooldown; interaction tests cover zero-effect and cooldown pressure rejection.
- Independent re-critique: **pass, 0.96 confidence**. It verified the authoritative pressure/cooldown contract, real state assertions, selection-HUD clearing, domain/interaction passes and main-scene boot.
- Visual readability, spatial mechanics, balance and target-player comprehension remain open gates. In particular, Vesper's `DASH` and Sable's `LONG_RANGE` are still result semantics rather than real position/range rules; post-match Q rejection is also not yet implemented.
