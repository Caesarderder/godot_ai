# Privacy declaration

Current runtime claim for this local Web build:

- No analytics SDK is integrated.
- No telemetry endpoint is configured.
- No crash-reporting endpoint is configured.
- No advertising SDK is integrated.
- No account login, email, phone number, geolocation, microphone, camera, contacts, or payment collection is implemented.
- No cookies are intentionally set by project code.

The game stores local progress and settings through Godot `user://` persistence. In Web exports this is expected to map to browser-managed origin storage. The data is intended to remain on the player's device/browser origin and is not intentionally transmitted by project code.

The settings screen also offers an optional **local playtest report**. It is disabled by default.
When the player explicitly enables it, the game records at most 256 whitelisted events: screen
names, command types and success/failure, battle stage/outcome, and relative timing. It does not
record free-form text, command payloads, save IDs, account IDs, device IDs, browser fingerprints,
or network addresses. The report stays in `user://`, can be downloaded by the player, and is deleted
with its backup when the player disables recording or selects the clear action. Project code never
uploads this report.

When the player downloads the report, the game derives a first-session summary from those same
whitelisted events: eight onboarding milestone timestamps, per-stage attempt counts, failed-command
count, navigation-only streaks, and the longest non-battle event gap. These values add no new source
data or identifier. They can help locate friction, but cannot establish player comprehension,
enjoyment, or intent to continue without observation and a neutral interview.

Stored local data may include:

- save schema version;
- run seed and save id;
- roster, formation, hero progression, factory queue, resources, command receipts, and auto-skill preferences;
- timestamps needed for offline production settlement.
- when explicitly enabled, a versioned local playtest session ID, relative event timing, screen names,
  command result categories, and battle result categories.

Known release limitations:

- Browser storage may be cleared, blocked, isolated by private browsing, or stranded by an origin/path change.
- A real Chrome private-context check confirms that reloads inside one private session can retain progress,
  while closing that context and opening a new private context produces distinct local data. The settings
  screen therefore does not present Godot's Web persistence capability flag as guaranteed retention.
- This declaration has not yet been validated on the final hosted HTTPS origin.
- If hosting, analytics, ads, crash reporting, account systems, CDN logs, or platform SDKs are added, this document must be updated to match the actual runtime behavior before release.

Public release remains blocked until production-origin privacy behavior, storage behavior, and any hosting/provider logs are reviewed against the final store/privacy requirements.
