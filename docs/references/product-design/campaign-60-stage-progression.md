---
km_id: reference.campaign-60-stage-progression
km_type: reference
domain: product
status: active
owner: game-design
last_verified: 2026-07-29
source_of_truth:
  - docs/game-contract.md
  - project-a/game/scripts/domain/content/stage_catalog.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
validated_by:
  - project-a/tools/run_stage_definition_tests.gd
  - project-a/tools/run_campaign_60_stage_tests.gd
tags:
  - reference:campaign
  - decision:campaign-progression
  - risk:ip-authorization
related:
  - reference.game-contract
  - reference.game-state-measurement-framework
  - reference.objective-hurdle-reward-ladder
---

# 第一幕 60 关持续战役合同

## 玩家承诺

首 30 分钟的 1-1～1-5 教学、首次成长和中型 Boss 保持不变。之后每章扩展为 12 关，
以三个关卡为一个循环：

1. 普通关：低压力展示新敌人或环境；
2. 检查点：仍可轻松通过，给一份可见小奖励；
3. 精英关：给大于普通关的奖励，并形成一次阵容、战力或科技检查。

每章 3、6、9 为精英关，12 为章节 Boss。6 是主要战力墙，要求升级、升星或调整阵型；
9 是专项科技墙，允许玩家硬打，但未研究反制科技时承受显著机制伤害；12 将战力墙、科技墙
和章节机制组合成期末考试。关卡数量增加不得把旧五关奖励总量按 2.4 倍膨胀。

## 原作剧情灵感边界

公开资料将原作主要演进概括为：城市被马桶人占领、Cameramen 抵抗与 Titan Cameraman 登场、
Speakermen 加入、寄生虫感染 Titan Speakerman、TV Men 与传送/屏幕能力登场、升级泰坦回归、
联盟渗透实验室并击败 Scientist Toilet，随后威胁继续升级到 Astro Toilets。

本游戏只把这些宏观节拍用于“势力登场顺序、机制教学和战役情绪”，不逐镜复制视频，不复制
对白、音乐、模型或动画。当前内容仍是原型；任何使用原作名称、角色外观或剧情进行商业发行，
都必须先取得权利方书面授权。

参考来源：

- 原作者官方入口与观看链接：<https://linktr.ee/official.dafuqboom>
- 系列与创作者概况：<https://en.wikipedia.org/wiki/Skibidi_Toilet>
- 社区整理的篇章与事件索引：<https://skibidi-toilet.fandom.com/wiki/Arcs>

## 五章主题与 60 关

| 章 | 原作感情绪 | 1–3 第一循环 | 4–6 第二循环 / 战力墙 | 7–9 第三循环 / 科技墙 | 10–12 收束 / Boss |
|---|---|---|---|---|---|
| 1 抵抗形成 | 城市沦陷、Camera 抵抗、巨型单位阴影 | 无防备城市；城市警报；联盟集结（精英） | 炮台防线；灰镜核心（保留首 30 分钟中 Boss）；摄像重装营（战力墙） | 失焦街区；黑屏预警；电视人闪袭（科技墙） | 镜片仓库；泰坦足迹；抵抗军总台（Boss） |
| 2 音波与寄生危机 | Speaker 援军、能量干扰、寄生失控 | 低音街垒；震荡高架；广播车队（精英） | 回声隧道；共振前哨；巨型音箱阵（战力墙） | 寄生样本库；失控广播站；感染泰坦投影（科技墙） | 静音走廊；解毒车队；共振堡垒（Boss） |
| 3 TV 技术战 | 消失、传送、屏幕控制、泰坦回归 | 信号消失；烟幕换位；镜片工厂（精英） | 处决画面；黑屏中继；电视监军（战力墙） | 传送残影；控制矩阵；夺控实验室（科技墙） | 暗屏走廊；泰坦回归；黑屏母塔（Boss） |
| 4 三族联合反攻 | Camera/Speaker/TV 模块协同、实验室渗透 | 联合标记；禁飞走廊；反寄生区（精英） | 轮换防线；三军前哨；联合近卫（战力墙） | 装甲列车；模块工坊；协议封锁（科技墙） | 渗透入口；实验室外环；三联军械库（Boss） |
| 5 科学家基地决战 | 科学家机甲、诱敌、连续炮击、G 军团 | 空城大道；战略仓库；泰坦足迹（精英） | 中央防区；审判前门；科学家机甲（战力墙） | 诱敌回廊；连续炮阵；指挥干扰核心（科技墙） | 实验室深层；G军团决战；审判之门（Boss） |

## 专项科技

| 章 | 科技 | 解锁前置 | 未研发压力 | 研发后 |
|---|---|---|---|---|
| 1 | 战术墨镜 | 1-8 | 电视人闪屏周期性重创全队 | 免疫致盲，闪屏伤害降低 80% |
| 2 | 共振绝缘层 | 2-8 | 共振抽取能量并延长易伤 | 能量损失与易伤持续降低 70% |
| 3 | 信号锚定器 | 3-8 | 消失、换位和控制连续打断输出 | 控制降低 75%，首次传送被揭露 |
| 4 | 联军协议解码器 | 4-8 | 标记、防空、净化、护盾轮换 | 模块持续降低 60%，显示下一模块 |
| 5 | 指挥核心稳定器 | 5-8 | 诱导撤退和炮击破坏技能循环 | 冲击伤害降低 75%，延长预警 |

每项科技只消耗工业材料，经 durable command exact-once 研发。科技不增加面板战力；
战前页必须分别显示“战力是否达标”和“反制科技是否覆盖”。

## 数值与奖励合同

- 每章推荐战力在章首和章末之间线性增长，6/9/12 叠加可见墙体修正。
- 1、4、7、10 为基础金币；2、5、8、11 增加小奖励；3、6、9 增加精英奖励；12 为 Boss 大奖励。
- 精英和 Boss 的军团数据只在首通发放，重复胜利降为基础奖励的 30%。
- 普通关不能卡住达标玩家；战力墙允许约一次明确失败；科技墙在未研发时困难、研发后应回落到推荐难度。
- 每章总奖励要覆盖下一章至少一项可见成长，但不直接送出足以跨越两堵墙的通用战力。
- 章节型设施与旧章节 Boss 图纸统一在 `x-12` 首通结算；新增角色按 `3/6/9` 精英、战力墙、科技墙节点分批投放，不能继续沿用旧五关制的 `x-5` 章节坐标。
- 当前角色投放为：2-12 自爆飞行与金币铸造厂资格；3-3 信号净化、3-6 锚桩堡垒、3-12 双锯；4-3 磁轨牵引、4-6 相位钻袭、4-9 协议编织。

## 技术影响图

| 合同 | Owner | 实现 | 验证 |
|---|---|---|---|
| 60 关顺序、名称、推荐线、奖励层级 | content | `stage_catalog.gd` | 60 个唯一 ID、4×3节奏、单调推荐线 |
| 科技研发与扣费 | commands/domain | `command_executor.gd` durable receipt | 前置、余额、exact-once、重复拒绝 |
| 科技墙战斗效果 | battle | `battle_session.gd` config-driven hazard | 同 seed 有/无科技损伤差异 |
| 12 关战区与章节进度 | UI | `slg_main.gd`, `war_zone_screen.gd` | 844×390 与 568×320 可操作 |
| 旧 25 关存档 | persistence | `save_codec.gd` migration | 不回退、不跳过已赢里程碑、不丢回执 |
| 剧情与 IP 边界 | product/legal | 本文与发布门槛 | 商业发布前书面授权 |
