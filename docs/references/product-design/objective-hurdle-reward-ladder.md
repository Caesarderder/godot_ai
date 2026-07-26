---
km_id: reference.objective-hurdle-reward-ladder
km_type: reference
domain: product
status: active
owner: game-design
last_verified: 2026-07-27
source_of_truth:
  - docs/game-contract.md
  - docs/references/constraints/first-30m-contract.md
  - project-a/game/scripts/domain/onboarding/onboarding_catalog.gd
  - project-a/game/scripts/domain/onboarding/onboarding_service.gd
  - project-a/game/scripts/domain/recruitment/research_breakthrough_service.gd
  - project-a/scripts/slg_main.gd
validated_by:
  - godot --headless --path project-a -s tools/run_research_breakthrough_tests.gd
  - godot --headless --path project-a -s tools/run_first_30m_journey_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
tags:
  - reference:objective-hierarchy
  - reference:hurdle-recovery
  - reference:reward-cadence
related:
  - reference.first-30m-contract
  - reference.meta-progression-system
  - reference.game-state-measurement-framework
---

# 目标、卡点与跨坎奖励阶梯

## 玩家可见目标层级

任何时刻只突出一条因果链，不把三层目标做成三个互相竞争的任务列表：

| 层级 | 时间尺度 | 玩家问题 | 首章示例 |
|---|---|---|---|
| 大目标 | 15–30 分钟 | 我为什么继续玩？ | 摧毁灰镜核心，完成第一章 |
| 中目标 | 2–8 分钟 | 这一段要证明什么？ | 研究突破、带队反攻、选择成长 |
| 小目标 | 10–90 秒 | 我下一步点什么？ | 挑战 1-4、启动十连、把装甲放进前排 |

目标中心按“大目标 → 中目标 → 小目标 → 当前坎 → 过坎办法 → 唯一主 CTA”呈现。小目标只认
领域结果，不以“打开页面”“点击页签”或重复领奖作为进度。长期日周任务在首章之外承担习惯组织，
不得抢占当前行动的视觉优先级。

## 卡点阶梯

| 卡点 | 频率 | 作用 | 恢复预算 |
|---|---|---|---|
| 小坎 | 30–120 秒一次 | 教会一个反馈或操作 | 立即重试、一次技能或一次明确提示 |
| 中坎 | 3–8 分钟一次 | 要求一次编队或成长决策 | 1–3 个可执行动作，资产不损失 |
| 大坎 | 每章 1–2 次 | 改变玩家理解或形成高潮 | 明确失败原因、保障资源、确定性逆转路线 |

首章的大坎一是 1-4 首败：单人职责不足；恢复链为首败战报 → 70 保障币 → 建研究所 →
免费研究突破十连 → 两名永久援军 → 三人反攻。大坎二是 1-5：基础三人不稳定；恢复链为读取
Boss 巨炮 → 在冲锋/装甲二星中自主选一条 → 再战。失败不会删除角色、扣除永久战力或制造等待。

卡点不是付费拦截器。若非付费玩家在设计时间窗内没有至少一条确定性恢复路径，则属于经济或关卡
缺陷，不允许用礼包、抽卡弹窗或任务文案掩盖。

## 研究突破十连

研究所落成后提供一次账号/存档级免费十连：

- 恰好展示十张结果；
- 固定包含 A 级冲锋与装甲两名永久援军；
- 其余八张是 1 枚技能芯片和首章可用工业资源；
- 不消耗招募券，不推进或重置长期招募 A/S 保底；
- 用 durable command receipt 和稳定 claim key 防止重复发放；
- 结果页直接指向编队，形成“失败原因 → 新能力 → 立即验证”的闭环。

这是对跨过大坎的庆祝和长期招募系统的低风险预览，不是假随机诱导。正式招募仍在首章完成后开放，
必须公开概率、保底和重复转化；不得在首败后立即出售战力解法。

## 商业化假设与边界

目标是提高玩家对角色收集、差异化阵容和长期成长的兴趣，而不是制造焦虑。可以在真人测试中验证：

1. 十连揭晓是否被玩家视为“我解决了问题后的奖励”；
2. 玩家能否说出冲锋和装甲分别解决什么；
3. 玩家在 1-4 反攻后是否愿意了解更多角色；
4. 玩家是否理解免费突破十连与长期招募保底互不影响；
5. 若移除任何付费入口，首章是否仍完整、顺畅且可达。

上线前商业化门禁：概率与保底法务文本、未成年人和地区合规、价格梯度、退款与恢复、付费前后
胜率差异、非付费 7/30 日可达性，以及至少五名目标玩家的无引导理解证据。
