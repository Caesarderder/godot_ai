# Builda Web Release Checklist

## Candidate

- [ ] Revision, dirty state, version, and artifact identity are fixed.
- [ ] Godot reports exactly `4.6.3-stable`.
- [ ] GDScript, Compatibility, and single-threaded Web constraints are satisfied.
- [ ] Current repository test and runtime evidence is complete and passing.
- [ ] Save schema, supported migration range, browser claims, and performance budgets are explicit.

## Controlled export

- [ ] Builda-controlled runtime, no-threads template, and shell were used.
- [ ] Export command/build identifier, exit code, duration, and logs are recorded.
- [ ] Artifact files, byte sizes, and hashes are recorded.
- [ ] No unexpected `.worker.js` artifact, debug-only control, secret, or private source file ships.
- [ ] A clean rebuild from the same revision is reproducible.

## Delivery and startup

- [ ] WebAssembly uses the correct MIME type and large files are compressed.
- [ ] Fresh-cache and warm-cache transfer sizes are within budget.
- [ ] Download, compile, first-frame, and interactive timings are within budget.
- [ ] Loading, failure, retry, and runtime diagnostic states are usable.
- [ ] Browser memory and frame-time budgets pass on the minimum target class.

## Browser runtime

- [ ] Supported Chromium and Firefox versions pass.
- [ ] Safari and mobile browsers pass when claimed.
- [ ] Mouse, keyboard, focus, and applicable gamepad paths pass.
- [ ] Audio unlock, mute/volume, and resume pass.
- [ ] Resize, aspect, pixel ratio, fullscreen/pointer capture as applicable pass.
- [ ] Focus loss, tab suspension, return, and long-pause recovery pass.
- [ ] Success, failure, restart, scene transitions, and return-to-menu pass.

## Persistence and compatibility

- [ ] Settings and progress survive reload and browser restart on the release origin.
- [ ] Unavailable or nonpersistent storage produces an understandable degraded path.
- [ ] Corrupt, truncated, oversized, and future-version saves are rejected safely.
- [ ] Every supported released schema migrates successfully.
- [ ] Backup/recovery and promised export/import paths pass.
- [ ] Origin/path changes do not silently strand saves, or the limitation is communicated and mitigated.

## Accessibility, licenses, and privacy

- [ ] Keyboard reachability, focus visibility, text readability/scaling, and non-color cues pass.
- [ ] Reduced motion and critical audio alternatives pass where required.
- [ ] Supported screen-reader behavior is tested on named browser/OS combinations.
- [ ] Every shipped asset/addon has source, license, distribution permission, and attribution status.
- [ ] Runtime data collection matches consent, privacy, retention, and age/region declarations.

## Hosting and operations

- [ ] Final HTTPS URL and deployment/version identifier are recorded before claiming live.
- [ ] Production-origin smoke tests pass on that exact URL.
- [ ] MIME, compression, cache, security, iframe, and origin behavior pass in production.
- [ ] Monitoring identifies release version and covers startup/runtime/save failures.
- [ ] Alert ownership and incident path are documented.
- [ ] Previous known-good artifact, rollback trigger, cache invalidation, and post-rollback smoke are tested.

Any required unchecked item means `BLOCKED`, unless hosting itself is the only unavailable evidence, in which case use `HOSTING_UNVERIFIED` rather than claiming release.
