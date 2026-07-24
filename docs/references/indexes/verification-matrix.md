---
km_id: reference.verification-matrix
km_type: reference
domain: quality
status: active
owner: verification
last_verified: 2026-07-24
source_of_truth:
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
  - project-a/tools/run_lifecycle_tests.gd
  - project-a/tools/run_ui_smoke_tests.gd
validated_by:
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
  - godot --headless --path project-a -s tools/run_lifecycle_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
  - godot --headless --path project-a --export-release Web build/web/index.html
  - visual-capture-1920x1080-and-844x390
tags:
  - reference:verification-matrix
  - quality:acceptance-gate
related:
  - reference.first-30m-contract
  - runbook.game-verification
---

# 验证矩阵

## 目标

把批准的 milestone 退出条件路由到 Godot Web-first 3D 证据。当前已有 Compatibility shell、v3 Meta、工厂/培育/六人编队和三阶段战斗自动化基线，但不代表 Web M0、完整长期 GDD、真机或平衡门禁已通过。

## 事实

| Milestone | 证据 |
|---|---|
| 当前 v3 可玩切片（PASS） | Godot 4.6.3 headless 导入、完整 App Shell 启动、GL Compatibility、Meta + Battle + Lifecycle + UI smoke tests、Web release export、1920×1080 与 844×390 视觉检查，以及 844×390 本地 HTTP 浏览器核心循环交互；不代表 Web M0、真机或完整长期 GDD 通过 |
| M0 Web shell（partial baseline） | Compatibility 与单线程 Web preset/export 已配置并验证；PWA、音频手势、持久性告警及 Chrome Android + Safari iOS smoke 未完成 |
| M1（partial baseline） | 已验证 command fingerprint/幂等/revision/先存后换、严格 JSON、v1/v2->v3 迁移、主备恢复与 bootstrap gate；internal Web lifecycle、刷新/关闭 crash matrix、20m+5m、600 replay 与离线战斗结算未完成 |
| M2（current baseline） | 已验证固定 seed 新档 8 英雄、指定配方生产永久英雄、L1-L5 clamp/growth、三材料八配方、3 队列、绝对时间离线到期/一次性领取、3 合 1、严格六槽、合成后编队引用迁移和 ID 单调性；真人可读性观察未完成 |
| M3（playable subset） | 已验证六人三阶段 5Hz 自动攻城、联盟普通/精英守军、7 结构目标、阶段切换、八原型 canonical 技能及星级机制变化、自动技能偏好跨存档、核心巨炮预警/命中、同输入同结果、超时、result-once 和 3D 薄投影；stable digest、跨 FPS、1-1/1-2/1-3 数值门禁及 paired +30pp 未完成 |
| M4 | 生产离线到期与 claim-once 已落地；装备、任务、离线战斗收益、完整经济 ledger、pity、soft quest、facility、1-4/1-5 区间和 1-5 paired +30pp 未完成 |
| M5 | 全部 headless、Web release export、Chrome Android + Safari iOS 性能/PWA、P01-P05、最终 scope audit |
| 当前 docs init | [CMD:docs-lint](../../runbooks/docs-lint.md#docs-lint) 零错误 |

技术自动/设备门槛为 100%；真人观察关键项各 >=4/5，总计 >=45/50。实现者不能自批，独立 verifier 保存原始输出、设备日志和 manifest hash。

## 入口或路径

[CODE:test-spec](../../../.omx/plans/test-spec-fantasy-idle-expedition.md)。

## 验证

使用 [CMD:game-verification](../../runbooks/game-verification.md#game-verification)；当前已验证 shell/UI smoke、v3 Meta、Battle、Lifecycle headless suite、Web release export 与 844×390 本地 HTTP 浏览器核心循环，其他命令在对应 milestone 落地前保持未验证。

## 相关节点

[KM:workflow.code-writing-review](../../workflows/code-writing-review.md)。
