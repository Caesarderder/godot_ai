---
km_id: reference.lossless-progression-balance
km_type: reference
domain: equipment-economy
status: active
owner: gameplay
last_verified: 2026-07-26
source_of_truth:
  - project-a/game/scripts/domain/factory/logistics_service.gd
  - project-a/game/scripts/domain/progression/hero_progression.gd
  - project-a/game/scripts/domain/progression/combat_power.gd
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/tools/run_slg_loop_tests.gd
validated_by:
  - godot --headless --path project-a -s tools/run_slg_loop_tests.gd
tags:
  - decision:lossless-battle
  - risk:economy-loop
related:
  - domain.equipment-economy
  - domain.factory-cultivation
  - domain.hero-formation
  - reference.game-state-measurement-framework
---

# 无战损成长数值合同

## 玩家循环

```text
工厂按时间产出三种工业资源
→ 城镇战斗产出金币、经验与工业技术
→ 玩家选择“角色成长”或“工厂成长”
→ 永久提高战力或产能
→ 挑战下一座城镇
```

战斗内生命、阵亡、治疗和撤退仍决定本局胜负；结算后所有永久角色保持 100% 可出征，不产生
战备损失、伤损清单、维修成本、维修等待或维修槽。失败的成本仅为本次操作时间和未获得胜利奖励。

## 资源职责

| 资源 | 主要来源 | 角色消耗 | 工厂消耗 |
|---|---|---|---|
| 金币 | 城镇、任务、长期进度 | 等级、技能 | 建造、设施升级 |
| 陶瓷 | 陶瓷厂 | 等级、升星、技能 | 设施升级 |
| 机械零件 | 零件车间 | 等级、升星、技能 | 设施升级 |
| 污水能源 | 能源站 | 等级、升星、技能 | 设施升级 |
| 工业技术 | 首次/重复占城 | 技能研究 | 设施升级 |
| 英雄数据/碎片 | 首通、Boss、招募重复 | 升星 | 无 |
| 技能芯片 | Boss、长期进度 | 高阶技能与三星 | 无 |

没有一种工业资源再用于恢复已经拥有的战力；每次消费都必须形成永久成长。

等级升级的运行时合同：

```text
upgrade_permanent_hero
→ 校验并扣除马桶币与三种工业资源
→ HeroProgression.upgrade_to_level
→ 同时更新 level、xp、base_stats、stat_remainders
→ CombatPower.hero_power 必须产生正向 ΔCP
```

角色成长的权威数值已收敛为五项：生命、攻击、防御、速度、暴击。四职业 B 评级每级成长分别为：

| 职业 | 生命 | 攻击 | 防御 | 速度 | 暴击 |
|---|---:|---:|---:|---:|---:|
| 守卫 | +20 | +2.4 | +4 | +1600 | +20bp |
| 战士 | +10 | +5.4 | +2 | +3200 | +40bp |
| 游侠 | +6 | +2.4 | +1.2 | +8000 | +100bp |
| 术士 | +5 | +6.3 | +1 | +2800 | +35bp |

C/B/A/S 评级只把上述升级成长乘 `0.85/1.00/1.15/1.30`，小数通过 milli remainder 累积；
初始基线不乘评级。星级只乘生命、攻击、防御，速度与暴击保持不变。标签：`implemented`。
固定 seed 能证明换算与战斗确定性，不能证明职业手感或关卡难度；后者仍为
`playtest hypothesis / unknown`。

旧 `train_hero`、`gold` 与 `xp_books` 只服务兼容入口和旧存档，不得用于当前 UI 成长建议、关卡预算或
永久英雄升级预览。

## 当前实现值

标签：`implemented`。

### 角色等级

目标等级为 `L`（2–5）：

```text
金币 = 30 × L
陶瓷 = 8 × L
零件 = 4 × L
能源 = 3 × L
```

对应单次成本：

| 升级 | 金币 | 陶瓷 | 零件 | 能源 | L1 生产等待 TFA |
|---|---:|---:|---:|---:|---:|
| 1→2 | 60 | 16 | 8 | 6 | 2.67 分钟 |
| 2→3 | 90 | 24 | 12 | 9 | 4.00 分钟 |
| 3→4 | 120 | 32 | 16 | 12 | 5.33 分钟 |
| 4→5 | 150 | 40 | 20 | 15 | 6.67 分钟 |

TFA 为三座一级资源设施并行生产、库存为空时的理论等待，不含金币获取时间。

### 角色升星

| 升级 | 数据/碎片 | 芯片 | 陶瓷 | 零件 | 能源 |
|---|---:|---:|---:|---:|---:|
| 1→2 | 4 | 0 | 18 | 10 | 8 |
| 2→3 | 8 | 2 | 36 | 24 | 20 |

### 主动技能研究

| 升级 | 金币 | 技术 | 芯片 | 陶瓷 | 零件 | 能源 |
|---|---:|---:|---:|---:|---:|---:|
| 技能 I→II | 80 | 6 | 1 | 24 | 16 | 20 |
| 技能 II→III | 160 | 12 | 2 | 48 | 32 | 40 |

### 设施升级

当前设施等级为 `L`（1 或 2）：

```text
金币 = 40 × L
工业技术 = 2 × L
陶瓷 = 20 × L
零件 = 12 × L
能源 = 16 × L
```

| 升级 | 金币 | 技术 | 陶瓷 | 零件 | 能源 |
|---|---:|---:|---:|---:|---:|
| 1→2 | 40 | 2 | 20 | 12 | 16 |
| 2→3 | 80 | 4 | 40 | 24 | 32 |

## 节奏目标

标签：`target` / `playtest hypothesis`。

- 首 10 分钟：至少完成 1 次角色升级、1 次设施升级与 2 次占城。
- 首 30 分钟：每 2–3 场出现一次可见成长；至少形成“主力等级、二星被动、设施 Lv.2”三类差异。
- 玩家在资源不足时应能明确选择等待工厂、重复攻城获取金币/技术，或改投更便宜的成长项。
- 失败不得降低账号状态；连续重试只受玩家意愿与当前战力限制。
- 工业资源库存不应因失去维修消耗而长期满仓；若真人样本中任一资源 30 分钟内持续高于容量
  80%，优先调整成长配方或增加同类永久成长，不恢复损耗型消耗。

## 验证边界

自动测试证明无损结算、旧存档归一化、成长扣款、升级属性与正向 `ΔCP`、唯一战力风险口径和首章战斗流程可达；完整 25 关经济可达性、是否好玩、成长频率是否舒适仍需
844×390 真人首 30 分钟试玩验证，不能标记为 `measured` 或“已平衡”。
