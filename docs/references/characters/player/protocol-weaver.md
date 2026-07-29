---
km_id: reference.character-player-protocol-weaver
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - docs/references/characters/specs/protocol-weaver.json
  - project-a/game/scripts/domain/progression/hero_progression.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/domain/factory/factory_catalog.gd
validated_by:
  - command:godot --headless --path project-a --script res://tools/run_new_character_tests.gd
  - python3 tools/docs_lint.py
tags:
  - reference:character-profile
  - reference:character-proposal
related:
  - reference.character-roster-index
---

# 寄生虫马桶人

> 状态：`implemented`。目录、长期招募、4-3首通图纸、研究、编队、战斗技能、科技树与程序化表现均已接入；玩家偏好仍为 `unknown`。

| 字段 | 生产合同 |
|---|---|
| ID / 分支 / 配方 | `protocol_weaver` / `special` / `special.protocol_weaver`（target） |
| 评级 / 职业 / 阵营 | S / `arcanist` / 干扰增殖 |
| 职责 / 承诺 | 夺取；拆掉可见敌方增益并改写为己方短期优势 |
| 获取 | 4-3后确定性试用/保底图纸路径；研究5秒；重复转40专属碎片（target） |
| 同类取舍 | 比音波上限高但必须等有效增益；比寄生更直接反精英但不制造额外目标 |

## 数值生产表

S级星级CP含140%稀有度基础倍率。

| Lv | HP | 攻 | 防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 120 | 42 | 17 | 92000 | 900 | 2168 | 2748 | 3338 |
| 2 | 126 | 50 | 18 | 95640 | 945 | 2463 | 3112 | 3771 |
| 3 | 133 | 58 | 19 | 99280 | 991 | 2735 | 3463 | 4188 |
| 4 | 139 | 66 | 20 | 102920 | 1036 | 3010 | 3824 | 4621 |
| 5 | 146 | 74 | 22 | 106560 | 1082 | 3293 | 4196 | 5092 |

Lv5星级战斗属性（含稀有度）：1★`204/103/30`，2★`265/134/40`，3★`327/165/49`。
目标射程110、移动9→10/tick、攻击周期6→5 tick、技能约30→25 tick。技能Lv1/2/3按
100%/120%/140%缩放己方护盾/攻击/速度效果，不增加可夺取数量；100能量。

| 星级 | 技能质变（target） |
|---:|---|
| 1★ | 移除精英1个带图标的可夺取增益，并按类型给最低血友军12 tick己方版 |
| 2★ | 改写协议扩散给同阶段2名友军，持续不叠加 |
| 3★ | 每场首次夺取Boss模块时存入协议槽；下次免费重放一次己方版 |

## 培养与内容

主路线为320战斗XP、660币、12数据、40+80=120碎片；经验书替代路线16书+900旧金币。
首次研究5秒无材料；兼容生产成本 `unknown`。关键路径不能依赖随机抽到S，4-4和Boss都保留回退。

教学链：4-4夺精英护盾 → 4-5在护盾/增伤中选时机 → 5-3反转加速 → 5-5每轮只夺一个模块。
回退为音波、火箭/双锯、装甲/维修、装甲/维修/双锯。织机信号环、三条数据丝和“敌音倒放—
己方主题短句”承担敌我转译。

## 效率、风险与验收

- `target`预算：有可夺增益时达到S级高光，无有效目标时明显弱于音波/寄生；CP不代表技能上限。
- `playtest hypothesis`：夺取令单次精英强化窗口缩短30%–50%；若能移除不可夺阶段、无限重放或覆盖所有友军则立即回滚。
- 首调可夺白名单、12 tick、扩散2人、协议槽每场一次；不先动S级基础倍率。
- 实现需统一buff ID/来源/可夺标签、己方映射、Boss槽持久范围、技能/招募/碎片/模型/科技/UI/关卡接线。
- 测试三类增益映射、无效空放、不可夺免疫、2★不叠加、3★仅一次且免费、保存不跨战泄漏、
  同预算回退seed；844×390必须明确“可夺取”、来源、己方版本和剩余时间。

最大未知：当前关卡模块增益可能不属于单位buff；若无法建立白名单映射，本角色应延期而非特判文案。
