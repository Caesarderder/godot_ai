---
km_id: reference.character-player-phase-tunneler
km_type: reference
domain: hero-formation
status: active
owner: game-design
last_verified: 2026-07-28
source_of_truth:
  - docs/references/characters/specs/phase-tunneler.json
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

# 武士刀蜘蛛马桶人

> 状态：`implemented`。目录、长期招募、4-2首通图纸、研究、编队、战斗技能、科技树与程序化表现均已接入；玩家偏好仍为 `unknown`。

| 字段 | 生产合同 |
|---|---|
| ID / 分支 / 配方 | `phase_tunneler` / `ordinary` / `ordinary.phase_tunneler`（target） |
| 评级 / 职业 / 阵营 | B / `fighter` / 快攻破城 |
| 职责 / 承诺 | 绕后；跳过前排，在短窗口拆后排结构或支援 |
| 获取 | 4-1后确定性图纸机会；研究5秒；重复转20专属碎片（target） |
| 同类取舍 | 比冲锋目标更深但风险更高；比火箭更能扰乱朝向但不能安全持续拆塔 |

## 数值生产表

| Lv | HP | 攻 | 防 | 速度 | 暴击 | 1★CP | 2★CP | 3★CP |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 150 | 36 | 28 | 92000 | 900 | 1724 | 2139 | 2574 |
| 2 | 160 | 41 | 30 | 95200 | 940 | 1884 | 2358 | 2832 |
| 3 | 170 | 46 | 32 | 98400 | 980 | 2044 | 2547 | 3080 |
| 4 | 180 | 52 | 34 | 101600 | 1020 | 2225 | 2787 | 3369 |
| 5 | 190 | 57 | 36 | 104800 | 1060 | 2385 | 2996 | 3617 |

Lv5星级属性：1★`190/57/36`，2★`247/74/46`，3★`304/91/57`。目标射程34、移动9/tick、
攻击周期6→5 tick、技能约30→25 tick。技能Lv1/2/3使钻出攻击、泄压口耐久或路径斩击为
100%/120%/140%，不改变有效目标；100能量。

| 星级 | 技能质变（target） |
|---:|---|
| 1★ | 钻到最远有效目标旁攻击一次后返回；核心、Boss、封闭区无效 |
| 2★ | 留8 tick泄压口，附近普通敌人短暂转向 |
| 3★ | 击破结构/支援后回程路径斩击并返50能量 |

## 培养与内容

主路线320战斗XP+660币+12数据+60碎片；经验书替代路线16书+900旧金币。首次研究5秒无材料，
兼容生产成本 `unknown`。

教学链：4-3绕后防空台 → 4-4在净化装置与支援间选目标并抓轮换暴露窗 → 4-5只拆军械模块。
回退为火箭、寄生/自爆、双锯/火箭、火箭/双锯/装甲。长锥钻头、黄色地下轨迹和左右移动声像
必须让玩家始终知道其去向。

## 效率、风险与验收

- `target`预算：拆单个后排窗口优于冲锋，持续结构输出和安全性低于火箭。
- `playtest hypothesis`：合理绕后令后排威胁提前15%–30%消失；若可无视Boss核心门禁或回程无风险即回滚。
- 首调目标规则、泄压8 tick、返能50；不先加攻击。
- 需实现临时离阵/返回、不可选区域、反潜预警、目标标签、技能/模型/招募/科技/关卡/保存接线。
- 测试最远有效目标、无目标失败、期间不可维修、返回原槽、2★转向、3★条件返能、确定性回放；
  844×390检查钻线路径、反潜警告和返回槽位。

最大未知：战斗阶段是否支持临时改变攻击侧与目标距离；实现前必须用最小战斗原型证明生命周期安全。
