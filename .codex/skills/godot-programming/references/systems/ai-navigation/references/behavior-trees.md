# Behavior Tree Routing

Behavior-tree implementation is intentionally not owned by `ai-navigation`.

- If a third-party behavior-tree addon is already present, follow its pinned project documentation.
- Do not install or assume an addon merely because a visual tree might be convenient.
- Keep path requests, movement, and avoidance in `ai-navigation`; inject targets or movement intents from the selected decision system.

Do not copy a custom BT framework into this skill. Confirm the addon exists in the project before using addon APIs.
