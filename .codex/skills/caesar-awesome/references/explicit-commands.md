# Caesar Awesome explicit commands

Use this reference when parsing an explicit Caesar command or deciding whether
knowledge-map initialization or Caesar Loop is authorized.

## Command grammar

Accept either canonical form:

```text
caesar-awesome:<command>
$caesar-awesome <command>
```

Supported commands:

| Command | Authorization | Internal route |
|---|---|---|
| `docs-init` | Create or structurally normalize a repository knowledge map. | Repository discovery, then [docs-init](../commands/docs-init.md) |
| `loop` | Start or resume the game-production Loop for the current request. | Repository discovery, Workbench control, then [Loop guide](loop-guide.md) |

Natural language is accepted only when intent is unambiguous:

- “初始化 Caesar 知识地图” is equivalent to `docs-init`.
- “开启/启动 Caesar Loop” is equivalent to `loop`.

Words such as “docs”, “game loop”, “core loop”, “iteration”, “review loop”,
“quality”, or “screenshot” do not authorize either command by themselves.

## Default route

When no explicit command is present:

1. Run repository docs discovery for non-trivial repository work.
2. Use Workbench task/HQ, existing-map update, or review behavior
   when its normal exemptions do not apply.
3. Use managed non-Loop document tools when relevant.
4. Do not initialize a missing map.
5. Do not load, create, resume, mutate, validate, or synchronize Caesar Loop
   artifacts.

## Command interaction

- `docs-init` does not enable Loop.
- `loop` does not imply that a missing knowledge map may be initialized; it may
  use an existing map or report that initialization needs `docs-init`.
- Both commands may appear in one request. Execute `docs-init` first, validate
  the map, start Workbench control, and then enter Loop.
- An explicit instruction to disable or stop Loop overrides an earlier command
  for subsequent work. Preserve already-written historical ledgers.

## Reporting

At route selection, report:

```text
Caesar command route:
- docs-init: enabled|disabled
- loop: enabled|disabled
- default procedures: discovery[, Workbench control]
- selected explicit procedures: ...
```

Never report Loop state when Loop was not enabled.
