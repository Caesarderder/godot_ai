---
name: game-web-release
description: Validate a release candidate for a Builda Godot 4.6.3 GDScript Web game. Use only when the user explicitly invokes $game-web-release or selects a skill book containing it; do not infer it from an ordinary implementation request. Separate build-ready, artifact-tested, and live-verified states.
---

# Game Web Release

Validate the exact release candidate and keep three states separate:

1. source is ready for a controlled build;
2. a Builda Web artifact was built and tested;
3. an external HTTPS URL was deployed, observed, and can be rolled back.

Never collapse these states into “released.”

Activation is explicit-only: ordinary build, fix, or implementation requests stay on Codex's native
path unless the user selects this workflow by name or through a skill book.

Read [references/web-release-checklist.md](references/web-release-checklist.md) before running the gate. Use [references/release-evidence-template.md](references/release-evidence-template.md) for the final record.

## Fixed platform contract

- Godot: exactly `4.6.3-stable` for Builda-controlled release evidence.
- Language: GDScript.
- Renderer: Compatibility / WebGL 2.
- Runtime: official, hash-verified no-threads Web template controlled by Builda.
- Threads: disabled; reject an unexpected worker runtime artifact.
- Export and preview shell: use the platform-controlled path. Do not download another editor/template or let a project replace the controlled shell.

If the candidate was built outside this contract, classify it as external evidence and do not call it a Builda-controlled release.

## 1. Freeze candidate identity

Record the revision, dirty state, project identity, release version, export preset, asset/license manifest, privacy declaration, save schema version, and exact test evidence being promoted. A later source change creates a new candidate.

Run the repository's release-candidate tests and runtime checks. Required checks that are stale,
missing, or `NOT RUN` block the release gate.

## 2. Produce and inspect the controlled export

Use the configured Builda build path and its pinned Godot runtime. Capture:

- Godot version and controlled template identity;
- export command or Builda build identifier, exit status, duration, and logs;
- artifact manifest, file sizes, and hashes;
- expected HTML, JavaScript bootstrap, WebAssembly, pack, and required assets;
- absence of an unexpected `.worker.js` artifact;
- reproducibility from the frozen revision.

Check release mode, main scene, Compatibility renderer, no debug-only controls, no missing imports, and no secrets or private source artifacts in the output.

A successful export proves only that an artifact exists.

## 3. Validate package and startup budgets

Measure on a fresh cache and a warm cache:

- transfer size and compression for the WebAssembly and pack files;
- correct MIME types, especially `application/wasm`;
- download, compile, initialization, first visible frame, and first interactive action;
- startup failure UX, retry behavior, and runtime diagnostics;
- memory and frame-time budgets on the documented minimum browser/hardware class.

Do not substitute desktop editor FPS for browser performance.

## 4. Exercise the browser matrix

Use the project's supported matrix. At minimum, test current supported Chrome/Chromium and Firefox; include Safari and mobile browsers when product scope claims them. Record exact versions.

Exercise:

- first load, reload, hard reload, and warm-cache load;
- required mouse, keyboard, and applicable gamepad paths;
- first-input audio unlock, mute/volume controls, and resume;
- responsive resize, relevant aspect ratios, device-pixel-ratio changes, and fullscreen or pointer capture when used;
- focus loss, tab hide/show, pause/resume, long suspension, and recovery;
- scene transitions, success, failure, restart, and return to menu;
- runtime errors, unhandled failures, and visible loading/error states.

Browser-specific failures block only the browser claims affected, but the release must not advertise unsupported browsers.

## 5. Prove persistence and migration

Test on the same origin intended for players:

- settings and progress across reload and browser restart;
- `user://` persistence availability and understandable degraded behavior;
- private browsing or blocked storage where practical;
- corrupt, truncated, oversized, and future-version saves;
- migration from every supported released schema;
- backup/recovery and import/export when promised;
- origin or path changes during deployment.

Never infer deployed persistence from local filesystem tests. Browser storage can be evicted or isolated by origin.

## 6. Close accessibility, license, and privacy gates

Require evidence appropriate to scope for keyboard reachability, visible focus, readable and scalable text, non-color critical cues, reduced motion, captions or visual alternatives for critical audio, and supported screen-reader behavior.

Inventory every shipped image, font, audio, model, code/addon, and generated asset. Record source, license, attribution requirement, and permission for distribution. Unknown provenance blocks release.

If analytics, crash reporting, remote services, cookies, or other storage collect or transmit data, document actual fields, purpose, retention, consent/opt-out, privacy policy, and age/region obligations. A policy document that does not match runtime behavior is a failure.

## 7. Separate build from hosting

After Builda produces an artifact, report `BUILD_READY` unless an authorized external hosting workflow actually deploys it.

To claim an externally hosted release, require:

- the final HTTPS URL and deployment/version identifier;
- production-origin smoke tests using that URL, not a local preview;
- correct cache headers, compression, MIME, content security, and iframe/origin behavior;
- version visibility and a tested previous artifact or rollback procedure;
- monitoring or diagnostics that identify release version without collecting prohibited user content.

If credentials, domain control, or hosting authority are unavailable, stop at `HOSTING_UNVERIFIED`. Do not manufacture or imply deployment evidence.

## 8. Verify monitoring and rollback

Before live approval, define and test:

- startup/load failures, runtime errors, save failures, and critical gameplay health signals;
- release/version correlation and safe browser/runtime dimensions;
- alert threshold, owner, and response path;
- rollback trigger, previous known-good artifact, cache invalidation behavior, and verification after rollback;
- player-facing incident and save-compatibility communication when needed.

Do not log prompts, credentials, save contents, or unnecessary player data.

## Verdicts

Use one verdict:

- `BLOCKED`: any required candidate, QA, export, browser, persistence, accessibility, legal/privacy, or operational evidence fails or was not run.
- `BUILD_READY`: controlled artifact and required artifact/browser checks pass; no external hosting claim was verified.
- `HOSTING_UNVERIFIED`: deployment was requested or expected, but the final external URL or production evidence is unavailable.
- `LIVE_VERIFIED`: the final HTTPS URL, production smoke, monitoring, and tested rollback evidence all pass for the exact candidate.

Report failed checks, exact evidence, supported browser claims, known limitations, deployment state, and the next action. Never describe `BUILD_READY` as online, published, or live.
