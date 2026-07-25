---
km_id: memory.index
km_type: memory
domain: agent-memory
status: active
owner: maintainers
last_verified: 2026-07-24
source_of_truth:
  - docs/workflows/knowledge-map-maintenance.md
  - docs/references/constraints/implementation-status.md
validated_by:
  - python3 tools/docs_lint.py
  - godot --headless --path project-a -s tools/run_meta_tests.gd
tags:
  - memory:index
related:
  - workflow.knowledge-map-maintenance
  - quality.stale-docs
---

# 项目记忆入口

## 目标

只保存经过验证、会改变未来工作方式的重复经验；不保存聊天记录、猜测或一次性 debug 过程。

## 已验证经验

- 用户已明确当前实现根为 `project-a/`，使用 Godot 4.6.3、3D 表现、Web-first 发布并主要在手机浏览器运行。
- `taptap/` 仅保留为历史原型；当前 Godot 工程已使用 GL Compatibility，并已实现和验证 v4 Meta、工厂/培育、六人编队、第一幕 25 关、任务/成就目标中心和三阶段战斗内核。
- Compatibility 与本地 PWA 构建不能替代生产 Web 证据；在浏览器持久性探测、音频解锁、生产 HTTPS 和真机 smoke 落地前，不得宣称正式 Web 上架通过。
- `quests/achievements` 已从骨架升级为已实现目标中心；以后不得再把任务或成就泛称为未实现。但 `inventory/pity` 仍只是部分经济/掉落骨架，不得据此宣称完整装备、掉落、离线或长期关卡平衡已实现。
- 成就系统的长期事实：schema v4 / `factory-siege-v4`，顶层 `achievements` 五桶，24 个永久一次性成就，奖励仅 `merit/gold/xp_books`，无日周限时/FOMO/广告/IAP/蓝图/战力倍率；旧档只回填可靠证据。
- Boss 巨炮压制已落地为战斗层输出竞速，不是新操作系统：仅章节 Boss `stage_in_chapter == 5` 最终基地阶段启用，20 ticks / 5Hz 约 4 秒窗口，五章目标 `70/85/100/115/130` 仍待人工平衡验证；达标 `cannon_suppressed` 取消炮击，失败保留 `artillery_impact`。不得把它写成新增货币、奖励、存档字段、任务、成就或已证明好玩的长期平衡结论。

## 触发条件

出现重复误判、稳定操作经验、确认过的技术债或新事实推翻旧节点时。

## 以后怎么做

先更新对应 workflow/domain/reference；只有跨任务仍有价值的反馈才新增 memory 节点。

## 验证依据

[KM:reference.implementation-status](../references/constraints/implementation-status.md)。

## 相关节点

[KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)。
