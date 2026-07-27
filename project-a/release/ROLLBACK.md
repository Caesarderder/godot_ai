# Web rollback runbook

This runbook covers the local, immutable rollback artifact. It does not claim that a production host,
CDN, monitoring system, incident owner, or rollback SLA has been configured.

## Freeze and rehearse

From `project-a/`, after `python3 tools/build_web_candidate.py` succeeds on a clean revision:

```bash
python3 tools/package_web_rollback.py --rehearse
```

The command writes a deterministic archive and JSON manifest under `build/rollback/`. It then extracts
the archive into a temporary directory, rejects unsafe members, verifies every file hash, and reruns the
local release artifact audit against the restored `web/` directory. It never replaces `build/web`.

## Local rollback triggers

Prepare to restore the last approved archive when any of these occurs:

- the candidate cannot reach an engine-ready Canvas;
- a service-worker/cache update produces a blank or stale mixed-version client;
- production-origin save identity or schema compatibility fails;
- a critical first-session, backup/restore, or offline smoke fails;
- the approved production error-rate, startup-time, or availability threshold is breached.

The final host must provide the numeric thresholds, monitoring source, named incident owner, version
switch command, cache invalidation procedure, and recovery-time objective. Until those are recorded and
rehearsed on the final HTTPS origin, the project is not `HOSTING_VERIFIED`.

## Safety

- Roll back static files only; never rewrite or downgrade a player's save.
- Confirm the target archive revision and SHA256 from its JSON manifest before upload.
- If the newer release wrote a schema the older build cannot read, stop traffic or serve a maintenance
  response instead of rolling back blindly.
- Keep the failed release artifact for incident analysis; do not overwrite the approved rollback archive.
