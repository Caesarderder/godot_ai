---
km_id: runbook.game-verification
km_type: runbook
domain: quality
status: draft
owner: verification
last_verified: 2026-07-24
source_of_truth:
  - .omx/plans/test-spec-fantasy-idle-expedition.md
  - project-a/project.godot
  - project-a/tools/run_meta_tests.gd
  - project-a/tools/run_battle_tests.gd
validated_by:
  - godot-4.6.3-headless-smoke
  - godot --headless --path project-a -s tools/run_meta_tests.gd
  - godot --headless --path project-a -s tools/run_battle_tests.gd
tags:
  - quality:game-verification
  - risk:partial-implementation
related:
  - reference.verification-matrix
  - reference.implementation-status
---

# 游戏验证 Runbook

> 当前 Godot 4.6.3 Compatibility v3 可玩切片、Meta/战斗/生命周期/UI smoke 测试、Web release export 和本地 HTTP 844×390 浏览器交互已通过；PWA、移动浏览器真机流程、跨帧率 digest 和 paired balance 尚未落地，因此保持 `draft`。

## 目标

在 M0-M5 分阶段验证 Godot Web-first 3D 项目、内容、经济、战斗和手机浏览器。

## 前置条件

本机提供 Godot 4.6.3 可执行文件；M0 落地后还需可写静态站点目录，以及 Chrome Android 和 Safari iOS 真机或等价远程调试环境。

## game-verification

当前可执行 shell smoke 和 v3 headless suite：

```powershell
godot --headless --path project-a --editor --quit
godot --headless --path project-a --quit-after 2
godot --headless --path project-a -s tools/run_meta_tests.gd
godot --headless --path project-a -s tools/run_battle_tests.gd
godot --headless --path project-a -s tools/run_lifecycle_tests.gd
godot --headless --path project-a --export-release Web build/web/index.html

# 本机 GUI Compatibility 视觉证据
godot --path project-a -s res://tools/capture_playable.gd
godot --path project-a --resolution 844x390 -s res://tools/capture_battle.gd

# 尚未落地：后续 M1-M5
godot --headless --path project-a -s res://addons/gut/gut_cmdln.gd
godot --headless --path project-a -s res://tools/validate_content.gd
godot --headless --path project-a -s res://tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
```

`run_meta_tests.gd` 当前覆盖：新档 8 英雄/250 金币/2 经验书/120 瓷/100 零件/80 污泥、固定 seed、L1-L5 培养、严格六槽、资源事务、战斗一次性结算、三材料八配方、三槽生产、绝对时间离线到期/一次性领取、3 合 1 升星、合成后编队引用迁移、自动技能偏好真实写盘/重载/自动施法、英雄 ID 单调、fingerprint 与幂等、business key 冲突、revision、保存失败、严格 JSON schema、v1/v2->v3 迁移、主档/备份恢复，以及启动加载/损坏存档 gate。

`run_battle_tests.gd` 当前覆盖：必须传入 6 人、默认六人队完成三阶段攻城、联盟普通/精英守军、阶段切换、7 个结构目标摧毁与核心电池→装甲→核心硬门控、手动/自动技能、八原型 canonical 技能及各自可观察效果、星级机制质变、核心炮预警/命中、结构损伤事件、同一快照得到相同结果、超时语义和 `battle_finished` 只产生一次。它尚不替代跨 30/60/120 FPS digest、paired balance 或移动设备性能门禁。

`run_lifecycle_tests.gd` 当前覆盖：新档 -> 工厂扣材生产 -> 到时领取永久英雄 -> 三个装甲原型合成 2 星并保持六槽有效 -> 使用真实编队构造战斗快照 -> 结算及 receipt exact-once。失败和超时会返回小额、不可替代胜利收益的残骸，避免生产资源归零后形成硬锁。

Web export 必须通过 HTTP(S) 静态服务访问，不能以 `file://` 作为证据。设备测试记录浏览器版本、机型、网络、冷启动、FPS、内存、前后台恢复、PWA 更新与存档持久性；所有等待必须限时。

## 预期结果

当前 App Shell 预期 headless 导入与主场景启动无错误；三套 suite 分别输出 `META TESTS PASS`、`BATTLE TESTS PASS` 与 `LIFECYCLE TESTS PASS`，进程退出码为 0；Web release export 生成 `index.html/.pck/.wasm`。844×390 本地 HTTP 浏览器应能看到完整中文标题，并可完成营地 -> 工厂生产/领取 -> 培育 -> 六人编队 -> 出征 -> 三阶段战斗 -> 结算交互，控制台无 error/warn。后续 M0 真机门禁仍要求 Chrome Android 与 Safari iOS 可进入游戏，不可持久环境显示明确告警，首次触摸后音频可用。

## 失败处理

失败保持 milestone active；先修复实现，再由独立 verifier 重跑，修复者不得自批。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。
