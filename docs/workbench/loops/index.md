---
km_id: map.caesar-loop-runs
km_type: map
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-31
source_of_truth:
  - docs/workbench/loops
validated_by:
  - command:python3 tools/docs_lint.py
  - command:python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py loop-sync --run-dir <run-dir>
tags:
  - workflow:agent-loop
  - quality:evidence-gate
related:
  - workflow.caesar-loop
  - workflow.workbench-hq
---

# Caesar Loop 运行索引

本页由 `loop-sync` 维护。先从运行节点读取玩家结果、Test Scenario 和门禁，再沿
`source_of_truth` 检查机器 JSON 与 ledger；不要从摘要推断完成。

<!-- loop-runs:start -->
| Run | 状态 | 知识节点 |
|---|---|---|
| `mobile_slg_ui_refresh_20260730` | `slice_building` | [KM:reference.caesar-loop-run-mobile-slg-ui-refresh-20260730](mobile-slg-ui-refresh-20260730.md) |
| `mobile_slg_ui_refresh_20260731` | `human_required` | [KM:reference.caesar-loop-run-mobile-slg-ui-refresh-20260731](mobile-slg-ui-refresh-20260731.md) |
| `ui_ux_gauntlet_20260731` | `integrating` | [KM:reference.caesar-loop-run-ui-ux-gauntlet-20260731](ui-ux-gauntlet-20260731.md) |
<!-- loop-runs:end -->
