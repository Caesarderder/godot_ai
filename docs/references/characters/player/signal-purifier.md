---
km_id: reference.character-player-signal-purifier
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - docs/references/characters/specs/signal-purifier.json
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

# 信号净化马桶人

> 状态：`implemented`。目录、长期招募、3-1首通图纸、研究、编队、战斗技能、科技树与程序化表现均已接入；玩家偏好仍为 `unknown`。

| 字段 | 生产合同 |
|---|---|
| ID / 分支 / 配方 | `signal_purifier` / `ordinary` / `ordinary.signal_purifier`（target） |
| 评级 / 职业 / 阵营 | A / `arcanist` / 干扰增殖 |
| 职责 / 承诺 | 净化；在控制落地前保住关键行动并暴露施法者 |
| 获取 | 3-1后确定性图纸机会；研究5秒；重复转30专属碎片（target） |
| 同类取舍 | 比音波更偏反应式防守、无先手控场；比维修能解控、但不擅长回血 |

## 数值生产表

| Lv | HP | 攻 | 防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 120 | 42 | 17 | 92000 | 900 | 1644 | 2042 | 2460 |
| 2 | 125 | 49 | 18 | 95220 | 940 | 1819 | 2260 | 2724 |
| 3 | 131 | 56 | 19 | 98440 | 980 | 1997 | 2484 | 3001 |
| 4 | 137 | 63 | 20 | 101660 | 1020 | 2176 | 2719 | 3282 |
| 5 | 143 | 70 | 21 | 104880 | 1061 | 2354 | 2960 | 3569 |

Lv5星级属性：1★`143/70/21`，2★`185/91/27`，3★`228/112/33`。目标射程110、移动9/tick、
攻击周期6→5 tick、技能约30→25 tick。技能Lv1/2/3只将备用护盾或反噬脉冲放大为
100%/120%/140%，不延长控制抗性；统一100能量与240币+12数据满级成本。

| 星级 | 技能质变（target） |
|---:|---|
| 1★ | 清最低血友军1个可驱散负面并给10 tick抗性；空放转弱护盾 |
| 2★ | 扩至同阶段，首个来源附加暴露标记 |
| 3★ | 成功阻断控制时，使来源20 tick不能再次施加同类控制 |

## 培养与内容

主路线总计660币+12数据+90碎片，另需320战斗XP；兼容经验书路线16书+900旧金币，互斥。
首次研究5秒且无材料；兼容生产成本为 `unknown`。

教学链：3-2慢速单控 → 3-3换位混控 → 3-4监军重复点控高光 → 3-5只净化可驱散模块。
已有回退为装甲、音波/维修、寄生/双锯、装甲/维修/音波。圆形白噪屏、旋转天线和白色扫描线
承担读招；音效为雪花噪声后接确认钟。

## 效率、风险与验收

- `target`预算：及时净化保存一次关键行动；提前空放不得提供等同装甲的护盾。
- `playtest hypothesis`：正确释放让受控tick下降25%–40%；若连续封锁Boss模块或成为第三章唯一解则回滚。
- 首调抗性10 tick、封锁20 tick、备用盾量；不加基础CP。
- 实现触点：可驱散标签、控制来源、技能Resource/目录、战斗事件、UI图标、招募/碎片、科技树、关卡推荐。
- 测试可驱散/不可驱散、空放、2★来源标记、3★同类封锁、种子回放、保存恢复及回退阵容；
  844×390必须同时读到目标、可驱散状态和倒计时。

最大未知：当前控制是否保留统一来源与类别；若没有，先建立显式状态合同，禁止按显示文本猜测。
