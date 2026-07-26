---
km_id: runbook.game-verification
km_type: runbook
domain: quality
status: draft
owner: verification
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/constraints/first-30m-contract.md
  - docs/references/constraints/implementation-status.md
  - docs/references/indexes/verification-matrix.md
  - project-a/project.godot
validated_by:
  - manual-new-contract-verification-review-2026-07-26
tags:
  - quality:game-verification
  - risk:major-migration
related:
  - reference.verification-matrix
  - reference.implementation-status
---

# 游戏验证 Runbook

> 当前 headless suite 已迁移核心 Meta、生命周期、UI、战役与首章闭环到永久角色 SLG 合同。
> 自动证据仍不能替代移动真机、真人体验、生产 HTTPS 与商业 IP 审查。

## 目标

分阶段验证永久角色、工厂后勤、城镇伤损、UI/UX、存档迁移和手机 Web。

## game-verification

### 当前自动与本地基线

```bash
godot --headless --path project-a --editor --quit
godot --headless --path project-a --quit-after 2
godot --headless --path project-a -s tools/run_app_bootstrap_tests.gd
godot --headless --path project-a -s tools/run_meta_tests.gd
godot --headless --path project-a -s tools/run_battle_tests.gd
godot --headless --path project-a -s tools/run_battle_hud_screen_tests.gd
godot --headless --path project-a -s tools/run_legion_screen_tests.gd
godot --headless --path project-a -s tools/run_factory_screen_tests.gd
godot --headless --path project-a -s tools/run_research_breakthrough_tests.gd
godot --headless --path project-a -s tools/run_goals_screen_tests.gd
godot --headless --path project-a -s tools/run_lifecycle_tests.gd
godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
godot --headless --path project-a -s tools/run_campaign_tests.gd
godot --headless --path project-a -s tools/run_stage_definition_tests.gd
godot --headless --path project-a -s tools/run_first_chapter_balance_scan.gd
godot --headless --path project-a -s tools/run_first_30m_journey_tests.gd
godot --headless --path project-a -s tools/run_platform_tests.gd
godot --headless --path project-a -s tools/run_presentation_tests.gd
godot --headless --path project-a -s tools/run_asset_3d_tests.gd
python3 project-a/tools/build_web_candidate.py
cd project-a && node tools/run_web_browser_smoke.mjs
```

浏览器 smoke 使用 Chrome DevTools Protocol 发出真实触控事件，进入可滚动设置页，下载并解析
v8 JSON 备份，再通过浏览器文件选择器完成预览与二次确认恢复；同时主动开启本地试玩报告，检查
版本、样本量、时间窗和禁止标识字段，验证在线/离线续接后关闭即删除；随后验证在线重载、Service Worker
接管、关闭本地 HTTP 服务后的离线 PWA 重启，以及 `/userfs` 主档与 `.bak` 身份不变。离线阶段
对图标和 manifest 的同源连接拒绝会作为缓存回退证据记录；其他控制台、脚本或网络错误仍会失败。
尺寸链路还必须模拟 568×320、667×375、844×390、932×430、1024×768、1280×540 与
390×844，确认短屏触控目标仍达到 48 CSS 像素、CSS 安全区探针生效、竖屏原生提示可读且输入被
拦截、平板和超宽横屏可用，并在恢复 844×390 后不丢失当前页面。
脚本从空白页接管 CDP 后才导航，因此异常和网络监听不会漏掉首次加载；它还会拒绝 dirty 或不可复现
的 `release-candidate.json`，记录 Chrome 精确版本，并分别测量新 profile 冷启动、Service Worker
接管后的热重载和服务器关闭后的离线重启。当前本地上限只用于发现回归，不能替代最低目标手机、
真实移动网络、压缩/CDN 或生产源测量。

`build_web_candidate.py` 会先在工程目录之外执行一次不晋级的导入缓存预热，再执行两次独立导出，
只有后两次完整文件哈希一致时才替换
`build/web`。这避免导出图标再次被 Godot 导入并把 `.import` 边车污染进候选包，同时写入绑定
commit、Godot 版本、线程模式和全量文件哈希的 `release-candidate.json`。正式候选要求
`project-a` 工作区干净；仅调试脚本自身时可显式使用 `--allow-dirty`，但这种结果会被审计拒绝。

已有候选产物也可单独复核：

```bash
python3 tools/release_audit.py --artifact-dir build/web
```

`run_factory_casualty_tests.gd` 现验证战后完全无损、结算幂等、schema v5→v8 与无尽进度兼容；
旧持久伤损、抽图和废料恢复断言不再执行。

### 阶段 0：迁移护栏

实施时新增：

- v6 golden save fixture；
- 新 schema round-trip；
- 迁移失败回滚；
- 旧资源与角色聚合映射；
- legacy wallet 封存；
- 重复迁移不产生第二份价值。

### 阶段 1：永久角色

至少覆盖：

- hero ID 唯一且永久；
- level/xp/star 边界；
- 三星技能、被动和工厂专长；
- 六槽唯一引用；
- 零战备出战拒绝；
- 升级、升星、派驻的余额不足和幂等。

### 阶段 2：工厂与维修

至少覆盖：

- 0 秒、正常离线、容量上限和时间回拨；
- 陶瓷、零件、能源的来源/消耗守恒；
- 设施门禁和功能节点；
- 快速、完全、计时维修；
- 维修槽与派驻；
- 全队重伤、金币为零时通过最低产能恢复。

### 阶段 3：战斗与城镇

至少覆盖：

- 永久角色战前快照；
- 胜利、失败、撤退和超时；
- damage/xp/reward manifest；
- 实时 HP 与战备度分离；
- 伤损、经验、奖励和进度 exact-once；
- 相同 seed/快照确定性；
- 5Hz、跨帧率 digest、三段攻城和核心巨炮回归；
- `BattleWorld` 只投影领域事件。

### 阶段 4：UI/UX

844×390 必须检查：

- 工厂：三资源、产速、容量、设施、维修；
- 军团：角色、等级、星级、技能、战备度、六槽；
- 战区：地图、敌情、真实战力比较、反制路线、奖励、开战；
- 目标：任务与里程碑；
- 战斗：阶段、技能、撤退、伤损预警；
- 结算：结果、真实角色贡献、机制复盘、成长和单一主 CTA。

不能横向滚动、遮挡主按钮、只用颜色表达伤损或由 UI 直接写持久状态。

### 阶段 5：首 30 分钟

自动流程与真人观察共同覆盖：

1. 收资源并升级角色；
2. 首胜获得金币/经验；
3. 快速整备；
4. 用工业技术升级设施；
5. 解锁星级节点；
6. 带伤继续；
7. 撤退或失败；
8. 无死锁恢复；
9. 击败章节 Boss。

真人必须能复述双向循环、区分 HP/战备度，并解释一次维修选择。

### 阶段 6：Web 候选

- Web release export 和 artifact audit；
- HTTP(S) 访问，不能用 `file://`；
- 本机 Chrome CDP smoke：844×390 Canvas、首屏进入基地、PWA、控制台/网络和 `/userfs` 存档刷新往返；
- Chrome Android 与 Safari iOS；
- 前后台、音频手势、刷新/关闭恢复；
- 8–12 小时离线结算和时间回拨；
- 20 分钟连续游玩、控制台、FPS 和内存；
- 商业 IP 与素材来源另作外部门禁。

## 预期结果

只有实现引用、自动证据、浏览器设备证据和真人证据满足对应合同，才能更新为 implemented/verified。

## 失败处理

失败保持里程碑 active；保留原始输出，先修复实现，再由独立 verifier 重跑。迁移失败必须回滚 v6 备份。

## 相关节点

[KM:reference.verification-matrix](../references/indexes/verification-matrix.md)。
