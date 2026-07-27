---
km_id: reference.original-series-character-codex
km_type: reference
domain: product
status: draft
owner: product-design
last_verified: 2026-07-28
source_of_truth:
  - docs/references/product-design/skibidi-toilet-lore-research.md
  - docs/references/product-design/earth-war-character-roster.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
validated_by:
  - command:python3 tools/docs_lint.py
  - manual-canon-and-roster-review-2026-07-28
tags:
  - domain:product
  - reference:character-roster
  - risk:canon-drift
related:
  - domain.product
  - domain.hero-formation
  - domain.battle-progression
  - reference.skibidi-toilet-lore-research
  - reference.earth-war-character-roster
  - reference.skibidi-toilet-idle-siege-gdd
---

# 《Skibidi Toilet》原作角色百科与游戏科技树底表

## 1. 文档用途

本文是后续角色科技树、英雄池、敌军名册、章节投放、模型排期和技能设计的背景底表。它回答：

- 玩家作为地球 Skibidi 指挥官，可以获得哪些马桶人永久友军；
- Cameramen、Speakermen、TV Men 在地球战争阶段可以提供哪些防守敌人；
- 同一角色的哪些形态是剧情升级，哪些只是战损、装备替换或社区称呼；
- 每个角色在原作何时进入故事，在游戏何时首次投放最容易被玩家理解；
- 哪些内容是原作事实，哪些是社区命名，哪些只是游戏改编建议。

本文不直接批准角色数值、抽取概率、模型制作或正式上线。当前产品仍遵守“Gman 开局、永久角色、
六人 `2×3` 编队、战后无损、工厂只生产后勤资源”的合同。

## 2. 收录边界

### 2.1 正史范围

- 基线为 DaFuq!?Boom! 原编号主线 Episode 1–79。
- `Skibidi Toilet: Emergence` 暂列为官方衍生资料，不混入基础角色池。
- DOM Studio、Virlance、MonsterUP、Roblox 游戏、模组和同人升级不属于本文正史。
- “所有角色”按游戏可用性解释为：全部主要具名角色、重要反复出现角色、可形成独立玩法的量产族群。
- 只换领带、裤色、头模或只在远景出现一次、没有独立行为的背景个体，合并进相应族群，不虚构独立技能。

### 2.2 证据等级

| 标签 | 含义 | 使用规则 |
|---|---|---|
| `原作明确` | 画面、对白、字幕或官方补充能确认 | 可作为故事和外形基线 |
| `社区通用` | 社区长期使用的描述性名称 | 可作工作名，宣传时不得声称为官方定名 |
| `策划归并` | 将多个近似背景单位整理成一个游戏原型 | 必须保留原型来源，不反写成原作事实 |
| `策划变体` | 为完整玩法职责而设计的非正史型号 | 只能用于本游戏平行战争线 |
| `未知` | 原作尚未解释 | 保留悬念，不擅自下结论 |

### 2.3 时代编码

| 时代 | 原作范围 | 核心变化 | 游戏章节建议 |
|---|---|---|---|
| E0 异常爆发 | Episode 1–6 | 普通马桶出现，人类秩序崩溃 | 序章 |
| E1 镜头反击 | Episode 7–20 | Cameramen 与 Titan Cameraman 入场 | 第一章 |
| E2 声波战争 | Episode 21–32 | Speakermen 加盟，Titan Speakerman 被寄生 | 第二章 |
| E3 屏幕军备竞赛 | Episode 33–49 | TV Men、反寄生与多层克制 | 第三章 |
| E4 泰坦反攻 | Episode 50–57 | Titan Cameraman 2.0、解除感染 | 第四章 |
| E5 Alpha-Hills | Episode 58–74 | Mutant、Scientist Mech、渗透战 | 第五章 |
| E6 Astro 入侵 | Episode 74–79 | 地球双方停战，Astro 成为共同敌人 | 第六章 |

## 3. 科技树总览

```text
玩家：地球 Skibidi 永久军团
├─ 领袖：G-Toilet 各时代形态
├─ 基础体型：Normal → Large → Giant
├─ 武装：冲锋 / 装甲 / 激光 / 火箭 / 酸液 / 锯刃 / 自爆
├─ 机动：Jetpack / Helicopter / Aircraft / Strider
├─ 特殊：Parasite / Glitch / DJ / Experimental
├─ 寄生宿主：Cameramen / Speakermen → 感染型永久角色
├─ 后勤：Scientist / Engineer / Repairer / Transporter
└─ 人形化：Prototype Mutant → Berserker / Buzzsaw / SWAT / Mafia / Female

地球战争敌军：Alliance
├─ Cameramen：通用火力 / 科研 / 反寄生 / 载具 / Titan
├─ Speakermen：冲锋 / 声波 / 舞步闪避 / Armada / Titan
└─ TV Men：屏幕控制 / 传送 / 救援 / 高技术 / Titan

后期共同敌军：Astro Toilets
├─ Trooper / Specialist / Interceptor
├─ Destructor / Obliterator / Impactor / Carrier
└─ Assailant / Detainer / Juggernaut / Duchess / Mothership
```

## 4. 玩家友军：领袖与核心具名角色

### 4.1 领袖级

| 稳定 ID | 角色 | 原作背景与首次时机 | 形态与升级关系 | 游戏职责 | 建议获得/投放 | 正史边界 |
|---|---|---|---|---|---|---|
| `skibidi.g_toilet.v1` | G-Toilet 早期形态 | E1 登场，地球 Skibidi 的战场领袖；后期确认与 Astro 有旧关系 | 基础巨型本体，早期以体型、眼部能量和指挥为主 | 初始领袖、均衡攻城、团队号令 | 新档唯一初始角色；序章只展示受限火力 | 不把他写成普通工厂量产单位 |
| `skibidi.g_toilet.v2` | G-Toilet 2.0 | E2 军备升级阶段，增加外置激光并配合感染 Titan Speakerman | v1 的正式武装升级 | 中程激光、对重甲、感染军团增益 | 第二章剧情升格或独立形态解锁 | 与 v1 不能只做换皮 |
| `skibidi.g_toilet.v3` | G-Toilet 3.0 | E4 与升级 Titan Cameraman 对抗时的强化形态 | 更多激光、推进与防护，但遭到重创 | 多炮齐射、飞行指挥、残局撤退 | 第四章 Boss 战前后解锁 | 强调“强但并非无敌” |
| `skibidi.g_toilet.v4` | G-Toilet 4.0 | E5 后期重返战场，装备核心、护盾、重装甲和强化推进 | 对 v3 的大规模重构 | 泰坦级攻城、护盾反击、核心爆发 | 第五章末传奇形态 | 不提前投放破坏前期威胁梯度 |
| `skibidi.g_toilet.v5` | G-Toilet 5.0 / Titan-body 候选 | E6 以后逐步展示的大型计划与新机械身体 | 属于后期独立战斗轮廓 | 终局领袖、对 Astro 泰坦单位 | 第六章后赛季；当前只预留 ID | 能力尚在扩展，未明部分保持 `未知` |
| `skibidi.chief_scientist.base` | 首席科学家马桶 | 早期出现，E2–E5 成为寄生、Strider、实验单位和升级工程的研发核心 | 本体与大型 Mech 必须拆分 | 召唤、控制、研究加速、战场布置 | 第一章作为导师；第三章解锁永久支援 | E5 后本人死亡，后期不能无解释复活 |
| `skibidi.chief_scientist.mech` | 首席科学家大型机甲 | E5 Alpha-Hills 决战的重型机体，本体在内部操控 | 不是肉体长大，是载具/机甲形态 | 召唤炮塔、多武器、阶段式传奇单位 | 第五章限时剧情角色或章节终局支援 | 与本体共享身份但拥有独立数据 |

### 4.2 G-Squad 与精英角色

| 稳定 ID | 角色 | 背景与首次时机 | 标志能力 | 游戏定位 | 投放建议 | 状态与限制 |
|---|---|---|---|---|---|---|
| `skibidi.dj.v1` | DJ Skibidi Toilet | E0 首次出现，以音乐和巨大音响形成极高辨识度；E5 回归 G-Squad | 音波、节奏、团队士气 | 史诗辅助、击退、充能 | 第二章支线招募 | 早期形态不应自带后期四激光 |
| `skibidi.dj.mech` | DJ Mech | E5 短暂出现的大型机械装备，未充分发挥便被 Detainer 摧毁 | 重型扬声器和多联武器平台 | 限时载具、守点火力 | 第五章剧情试用 | 是外部机甲，不是 DJ 本体升级完成态 |
| `skibidi.dj.v2` | DJ 2.0 | E6 以 G-Squad 强化形态作战 | 多扬声器、四激光、装甲、喷气 | 团队增益、远程偏转、飞行辅助 | 第六章永久升级 | 与 DJ Mech 分开处理 |
| `skibidi.glitch` | Glitch Skibidi Toilet | E3 出现的极高速特殊个体 | Sonic Charge、高速撞击 | 刺客、后排突入、单次爆发 | 第三章挑战角色 | 本体死亡后不可在后期正常出场 |
| `skibidi.berserker_mutant` | Berserker Skibidi Mutant | E5 活跃的重型人形 Mutant，后加入 G-Squad | 巨力、跃击、肩炮、钩爪、低血压制 | 重装战士、嘲讽、破甲 | 第五章确定性招募候选 | 后期 Astro 模块作为星级质变 |
| `skibidi.buzzsaw_mutant` | Buzzsaw Skibidi Mutant | E5 的标志性锯刃近战个体，G-Squad 核心成员 | 锯刃、刀剑、后期 Astro 激光与 EMP | 持续近战、缴械、短控 | 第五章精英招募 | 原型、基础与后期强化可做三个外观阶段 |
| `skibidi.swat_mutant` | SWAT Skibidi Mutant | E5 战损后被 G-Squad 接纳并维修 | 战术装甲、火箭、能量镰刀/近远混合 | 多用途副坦、对空 | 第五章末或第六章 | 具体武器名称采用画面描述，不扩大为官方定名 |
| `skibidi.mafia_mutant` | Mafia Skibidi Mutant | E6 获得 Semi-Titan 级机械身体后参战 | 半泰坦体型、激光、酸液武器 | 高成本重装、精英歼灭 | 第六章传奇候选 | 早期 Mafia Toilet 与后期身体视为同一角色两形态 |
| `skibidi.female_mutant` | Female/Heroine Mutant | E5–E6 的敏捷型女性 Mutant | 爪、激光、快速近战 | 游击输出、后排猎杀 | 第五章支线 | 名称以社区通用标注，不自行补人物身世 |
| `skibidi.michael_experimental` | Michael Jackson Skibidi Toilet | Scientist 实验单位，后成为 G-Squad 战士；E6 为同伴牺牲 | 高机动近战与实验强化 | 活动剧情角色、爆发战士 | 若采用仅限剧情/联动审查后 | 涉及第三方肖像与音乐风险，不建议进入基础商业角色池 |
| `skibidi.isaac_scientist` | Isaac Kleiner Skibidi Toilet | E5 G-Squad 科研与助手角色 | 分析、研发、指挥辅助 | 科研派驻、技能冷却辅助 | 第五章后勤角色 | 名称与形象存在第三方资产识别风险 |
| `skibidi.repairer` | Repairer Skibidi Toilet | E5 随 G-Squad 执行维修与升级 | 现场修复、模块安装 | 治疗/护甲修复 | 第一章即可用策划归并版；E5解锁具名外观 | 不把维修等同复活 |
| `skibidi.welder` | Welder Skibidi Toilet | E5 工程队成员，撤离途中被 Detainer 击杀 | 焊接、快速装甲修补 | 护盾与持续修复 | 第五章剧情角色 | 死亡后仅能以早期时间线使用 |
| `skibidi.forklift` | Forklift Skibidi Toilet | E5 参与运送和安装 DJ 等大型模块 | 搬运、装填、部署 | 召唤障碍/部署武器 | 工厂派驻或剧情 NPC | 不强行设计成正面输出英雄 |
| `skibidi.double_transporter` | Double Transporter Toilet | E5 运送 G-Toilet 关键升级组件，多台个体承担同类任务 | 双货箱、重载运输 | 战术补给、技能充能 | 第五章护送关或支援召唤 | 是量产族群，不是唯一具名人物 |

## 5. 玩家友军：基础与量产族群

以下条目是“可成为永久角色的原型”。同一原型可在招募中生成不同英雄实例，但不能暗示原作中的
所有背景个体都是同一个人。

### 5.1 体型与正面战斗

| 稳定 ID | 原型 | 原作时机与背景 | 可见特征 | 游戏职责 | 科技/星级方向 |
|---|---|---|---|---|---|
| `skibidi.normal` | 普通马桶人 | E0 起构成最基本群体 | 标准陶瓷底座、近距离咬击/冲撞 | 低门槛前排 | 头盔、护甲、冲锋、数量协同 |
| `skibidi.medium` | 中型马桶人 | E0–E1 作为体型升级梯度 | 更大体型和生命 | 均衡战士 | 装甲或单武器分支 |
| `skibidi.large` | 大型马桶人 | E1 起对普通 Cameramen 构成重压 | 可抓取、撞击小型敌人 | 承伤、破阵 | 重甲、激光、火箭 |
| `skibidi.giant` | 巨型马桶人 | E1 后作为精英和攻城单位 | 巨型轮廓、建筑级破坏 | 小型 Boss/高费坦克 | 多武器平台，不直升为 G-Toilet |
| `skibidi.armored` | 装甲马桶族 | 军备竞赛中持续出现 | 金属外壳、头盔、护脸 | 防御坦克 | 核心护盾、反冲击 |
| `skibidi.balaclava` | Balaclava/蒙面战斗马桶 | 多个时期出现的战斗外观族群 | 蒙面、较强肉搏感 | 冲锋精英 | 近战压制、掩体突入 |

### 5.2 火力武装

| 稳定 ID | 原型 | 原作背景 | 标志装备 | 游戏职责 | 科技/星级方向 |
|---|---|---|---|---|---|
| `skibidi.laser.single` | 单激光马桶 | E1 军备升级产物 | 单门激光 | 精确远程 | 充能、穿透 |
| `skibidi.laser.dual` | 双激光马桶 | 中期常见重火力 | 双联激光 | 持续对甲 | 同步齐射 |
| `skibidi.laser.quad` | 四激光马桶 | 中后期高火力族群 | 四门激光 | 精英炮台 | 过热管理、扫射 |
| `skibidi.rocketeer` | 火箭马桶 | E1 后以爆炸范围压制联盟 | 单/双火箭发射器 | 范围攻城 | 多联装、制导 |
| `skibidi.multi_rocketeer` | 多联火箭马桶 | E5–E6 的升级火箭平台 | 多枚火箭和推进结构 | 后排轰炸 | 弹幕、破盾 |
| `skibidi.artillerist` | 炮兵马桶 | 中后期远距离火力族群 | 重炮/多联炮 | 结构破坏 | 弹道范围、攻城增伤 |
| `skibidi.acid` | 酸液马桶 | E4 前后对 Titan 装备造成显著威胁 | 酸桶、喷射器、酸液弹 | 腐蚀、持续破甲 | 扩散、降防 |
| `skibidi.saw` | 锯刃马桶 | E3–E5 多种锯刃构型出现 | 前锯、侧锯或多锯片 | 近战拆甲 | 双锯、旋转防御 |
| `skibidi.flamethrower` | 火焰喷射马桶 | E4 重型战场单位 | 火焰喷射 | 范围持续伤害 | 燃烧地带 |
| `skibidi.sonic` | 音波马桶 | 策划变体，源自 DJ/扬声器技术 | 外置扬声器 | 群体打断 | 声波护盾、技能充能 |

### 5.3 飞行、突袭与自爆

| 稳定 ID | 原型 | 原作时机与背景 | 标志能力 | 游戏职责 | 科技/星级方向 |
|---|---|---|---|---|---|
| `skibidi.flying` | 飞行马桶 | 早期出现悬浮/飞行个体，其中部分后被归入 Astro 旧成员 | 空中机动 | 轻型后排突袭 | 后续地球型号改用明确推进器 |
| `skibidi.jetpack` | 喷气背包马桶 | 地球阵营仿制和普及喷气技术 | 后置喷气包 | 绕前排、对后排 | 双喷口、装甲 |
| `skibidi.helicopter` | 直升机马桶 | 空中运输和攻击族群 | 螺旋桨/机身武装 | 空中支援 | 运载、火箭 |
| `skibidi.airplane` | 飞机马桶 | E5 G-Squad 撤离时承担空中掩护 | 飞机式机体 | 快速轰炸 | 编队空袭 |
| `skibidi.flying_rocket` | 火箭飞行马桶 | 飞行与爆炸火力组合 | 喷气与火箭 | 远程范围攻城 | 多联齐射 |
| `skibidi.kamikaze` | 自爆马桶 | 多时期以低成本换取高爆发 | 炸药/冲撞 | 范围爆发 | 当前游戏永久角色必须改写为“无人爆破载荷”，不能永久死亡 |
| `skibidi.kamikaze_flying` | 飞行自爆马桶 | 绕过地面防线的自爆变体 | 飞行推进、自爆载荷 | 后排清场 | 3 星取消角色自损，仅消耗载荷 |

### 5.4 Strider 与机械载具

| 稳定 ID | 原型 | 原作背景 | 标志能力 | 游戏职责 | 升级关系 |
|---|---|---|---|---|---|
| `skibidi.strider.base` | 基础 Strider | Scientist 开发的机械足路线 | 多足移动、跨越地形 | 机动射手 | 基础底盘 |
| `skibidi.strider.armed` | 武装 Strider | 在基础底盘加装枪械或炮塔 | 移动射击 | 中程压制 | `base → armed` |
| `skibidi.strider.dual_laser` | 双激光 Strider | 典型激光升级型号 | 双激光 | 对盾持续输出 | `armed → dual_laser` |
| `skibidi.strider.launcher` | 火箭/发射器 Strider | 重型远程型号 | 火箭发射器 | 范围攻城 | 与激光为并列分支 |
| `skibidi.strider.heavy` | 重装机械 Strider | E5–E6 的后期重构 | 装甲、复合武器 | 高费移动炮台 | 可吸收 Astro 残骸升级 |

### 5.5 寄生、实验与后勤

| 稳定 ID | 原型 | 原作背景和首次时机 | 标志能力 | 游戏职责 | 使用边界 |
|---|---|---|---|---|---|
| `skibidi.parasite.normal` | 普通寄生马桶 | E2 Scientist 的关键反转技术 | 附着并控制普通联盟单位 | 短时策反 | 被反寄生枪克制 |
| `skibidi.parasite.large` | 大型寄生马桶 | 用于控制大型甚至 Titan 级目标 | 更强附着和控制 | Boss 机制、精英控制 | 不能常规永久控制 Titan |
| `skibidi.parasite.helicopter` | 寄生运输/直升机型 | 搭载寄生单位进入战场 | 空投寄生体 | 召唤支援 | 飞行本体与寄生幼体分开结算 |
| `skibidi.parasite_mother` | 寄生母体 | 策划归并原型 | 周期部署幼体 | 永久召唤英雄 | 明确是游戏变体 |
| `skibidi.scientist` | 科学家马桶族 | 各时期从事研究与武器改造 | 分析、实验设备 | 控制/派驻 | 与首席科学家不是同一人 |
| `skibidi.engineer` | 工程马桶族 | 战地安装和维修 | 工具臂、模块 | 护盾、部署 | 策划可归并 Repairer/Welder 的低阶原型 |
| `skibidi.transporter` | 运输马桶族 | 运送部队、箱体和升级件 | 货箱、重载结构 | 补给支援 | 不作为高输出角色 |
| `skibidi.experimental` | 实验马桶族 | Alpha-Hills 的多种特殊改造 | 不统一 | 活动/机制角色 | 每个具体实验体需单独立项 |
| `skibidi.g_clone.laser` | 激光 G-Clone/诱饵 | E4–E5 出现模仿 G-Toilet 的大型诱饵与克隆 | 多联激光 | 高费攻城 | 不是 G-Toilet 本人 |
| `skibidi.g_clone.rocket` | 火箭 G-Clone | G 外形的火箭武装分支 | 多联火箭 | 范围爆破 | 与激光型并列 |
| `skibidi.g_clone.buzzsaw` | 锯刃 G-Clone | G 外形的近战破甲分支 | 多锯刃 | 拆甲坦克 | 与其他 G-Clone 共用底盘 |

## 6. 寄生宿主科技树

### 6.1 核心构想

寄生技术不只是一场战斗里的短时控制技能，而是玩家打开第二套角色树的钥匙：

```text
击败并记录联盟单位
  → 回收宿主数据/反寄生设备残骸
  → 研究所完成“宿主适配”
  → 培育对应寄生体
  → 解锁感染型永久角色
  → 用星级提高同步率并保留更多宿主能力
```

玩家没有“生产一个 Cameraman”，而是研发一套能稳定控制该类宿主的寄生协议。完成研发后获得的
角色是“寄生体 + 宿主机械身体”的永久组合资产。战斗中的倒地只表示本局宿主失去行动能力；
结算后由工厂完全修复，不造成永久死亡或再次消耗一个敌方俘虏。

这条树带来三层价值：

1. **收集动机：** 每遇见一种新守军，玩家都会自然产生“以后能不能把他变成我的角色”的期待。
2. **玩法反转：** 敌人第一次展示机制，玩家研究后再把同一机制用于后续关卡。
3. **阵营叙事：** Scientist 的寄生技术从一次剧情奇袭，成长为马桶军团学习联盟科技的系统。

### 6.2 解锁循环

| 阶段 | 玩家行为 | 系统结果 | 可见反馈 |
|---|---|---|---|
| 发现 | 首次遭遇可寄生敌人 | 图鉴出现未知宿主剪影 | 显示其职业，但隐藏完整能力 |
| 解析 | 击败目标、完成特殊条件或摧毁其反寄生护卫 | 获得一次性的“宿主数据” | 战报显示已记录弱点 |
| 适配 | 在研究所投入工业技术、污水能源和机械零件 | 解锁该宿主的寄生协议 | 研究槽展示寄生体接管过程 |
| 稳定 | 完成角色专属研究任务 | 获得 1 星感染型永久角色 | 宿主外形保留，出现寄生附着和黄色阵营信号 |
| 同步 | 使用角色、获得对应数据或碎片 | 提升星级与同步率 | 更多宿主技能恢复，失控副作用降低 |

宿主数据是一次性解锁资格，不进入随机材料混池；玩家已经获得角色后，不需要反复捕获同类敌人维持角色。

### 6.3 科技层级

| 科技节点 | 前置 | 解锁内容 | 玩法意义 | 正史依据 |
|---|---|---|---|---|
| `parasite_organism` 寄生体培育 | E2 Scientist 剧情 | 普通寄生体、寄生母体 | 开启寄生技能和宿主图鉴 | 原作明确 |
| `camera_neural_map` 镜头神经映射 | 击败普通 Cameraman | 普通感染 Cameraman | 首个远程友军宿主 | 原作存在被感染 Cameramen |
| `large_host_anchor` 大型宿主锚定 | 普通宿主 2 星、取得大型样本 | Large Cameraman、基础重型宿主 | 为马桶阵容补充人形重装 | 原作技术可控制大型宿主 |
| `speaker_frequency_sync` 音响频率同步 | 遭遇 Speakermen、建成声波实验台 | Normal Speakerman | 解锁声波近战分支 | 原作明确存在感染 Speakermen |
| `titan_parasite_protocol` 泰坦寄生协议 | 章节 Boss 条件、Large Parasite | Infected Titan Speakerman 剧情形态 | 章节级反转，不是常规生产 | 原作明确 |
| `host_weapon_retention` 宿主武器保留 | 两种宿主达到 2 星 | 狙击、工程、火箭等职业宿主 | 从“借身体”发展为“继承职业” | 策划推导 |
| `anti_purge_carapace` 抗净化甲壳 | 回收反寄生枪/坦克残骸 | 净化抗性、脱离后短时再附着 | 回应联盟反制科技 | 策划推导，源自原作反寄生设备 |
| `autonomous_symbiosis` 自主共生协议 | 第三章末、首席科学家研究 | 高同步感染英雄、战后自动恢复 | 解释永久角色与战后无损 | 游戏原创合同 |
| `tv_signal_interface` TV 信号接口 | Astro/TV 技术研究 | 只开放研究悬念，不直接给感染 TV Man | 为后期分支留口 | 普通 Skibidi 寄生 TV 未获原作证明 |

### 6.4 可研发宿主角色

| 稳定 ID | 感染型友军 | 来源敌人 | 保留能力 | 寄生后变化 | 建议解锁 | 正史置信 |
|---|---|---|---|---|---|---|
| `host.camera.grunt` | 感染 Cameraman | `camera.normal.v1` | 中程射击、战场记录 | 转为黄色敌我识别，寄生体提供短时狂热 | 第二章首个宿主 | 高 |
| `host.camera.jetpack` | 感染喷气 Cameraman | `camera.normal.v2` | 飞行、枪械、镜片 | 寄生体强化突入但降低精准 | 第三章 | 中，具体量产形态为策划归并 |
| `host.camera.large` | 感染 Large Cameraman | `camera.large.v1` | 高生命、抓取、重击 | 成为人形重装前排 | 第二章后段 | 高 |
| `host.camera.sniper` | 感染 Sniper Cameraman | `camera.sniper` | 标记、蓄力狙击 | 可对被寄生标记目标追加伤害 | 第三章支线 | 策划推导 |
| `host.camera.engineer` | 感染 Engineer Cameraman | `camera.engineer` | 修复设施和机械体 | 改为维修马桶装备、部署寄生巢 | 第三章支线 | 策划推导 |
| `host.camera.medic` | 感染 Medic Cameraman | `camera.medic` | 单体修复 | 治疗宿主与 Mutant，不能复活 | 第三章 | 策划推导 |
| `host.speaker.grunt` | 感染 Speakerman | `speaker.normal.v1` | 快速近战、声波、舞步 | 声波附带寄生干扰 | 第二章中段 | 高 |
| `host.speaker.large` | 感染 Large Speakerman | `speaker.large.v1` | 范围震荡、高力量 | 成为击退坦克 | 第二章末 | 中高 |
| `host.speaker.specialist` | 感染武装 Speakerman | 精英音响宿主 | 武器与声波组合 | 提供团队攻击节奏 | 第三至五章 | 策划归并 |
| `host.titan_speakerman.infected` | Infected Titan Speakerman | `speaker.titan.v1` | 泰坦机动、双臂炮、声波 | 受大型寄生体控制，为 Skibidi 作战 | 第二章剧情试用 | 原作明确 |

### 6.5 暂不可寄生对象

| 对象 | 原因 | 正确的后续路线 |
|---|---|---|
| TV Men | 原作未证明普通 Skibidi 寄生能接管 TV 个体；其身体、传送和信号结构可能不同 | 先作为研究悬念；以后若采用必须标记游戏原创实验分支 |
| Titan Cameraman | 原作没有被 Skibidi 寄生控制的事实 | 可回收其装备技术，但不直接开放感染形态 |
| 具名英雄 | 捕获会破坏原作故事连续性，且容易把独特人物降格为量产皮肤 | 只在平行挑战、限时假设关或明确剧情分支使用 |
| 载具与炮塔 | 它们没有可供寄生的独立宿主 | 进入“残骸逆向工程”科技树，而非寄生树 |
| Astro Toilets | 生理和核心结构与地球宿主不同，且技术优势过大 | 第六章建立独立 Astro 逆向与抗控制树 |
| Watchman of Doom | 这是 Astro Core Penetrator 对 Titan TV Man 的核心劫持 | 作为需要解除控制的 Boss，不归入 Skibidi 寄生研发 |

### 6.6 星级与同步率

感染宿主的星级不表示又捕获了更多同一角色，而表示寄生协议稳定度：

| 星级 | 同步状态 | 机制表现 |
|---|---|---|
| 1 星：强制接管 | 能移动和使用基础攻击，但宿主高级职业能力受抑制 | 解锁基础角色；偶尔出现短暂僵直作为技能代价 |
| 2 星：神经同步 | 寄生体能调用宿主的职业装备 | 解锁狙击标记、工程部署或声波连击等被动 |
| 3 星：稳定共生 | 宿主能力与 Skibidi 技术形成组合 | 主动技能质变，移除随机失控，不增加操作不确定性 |
| 4 星以上 | 后续长期内容 | 可以增加抗净化、跨阵营组合技，不纳入首个切片 |

“失控”只能是可预测的技能代价或演出，不能让永久角色随机背叛玩家，否则会破坏战斗可读性和
确定性结算。

### 6.7 阵容与克制

- 感染宿主占用正常六人编队槽，不额外扩编。
- 同一宿主原型可存在多个永久英雄实例；具名角色和 Titan 仍保持唯一。
- 反寄生枪、净化坦克和 TV Woman 的解除技术会成为这条科技树的直接天敌。
- 玩家可以用装甲马桶保护感染远程宿主，用寄生母体延长宿主同步，用 DJ 稳定声波宿主。
- 宿主不应全面优于原生马桶：它们继承联盟职业能力，但更怕净化、屏幕干扰和寄生体被精准攻击。
- 第六章双方停战后，寄生新 Alliance 个体会产生叙事冲突；此时新宿主来源改为早期保存的协议、
  无主机械身体或自愿实验分支，不能继续表现为绑架临时盟友。

### 6.8 首次教学节拍

```text
第二章第一次遭遇 Speakerman
  → 玩家看到高速声波敌人并被击退
  → Scientist 提示“获取完整宿主记录”
  → 击败精英并取得音响频率样本
  → 研究所出现 Speaker 宿主剪影
  → 完成寄生适配，获得 1 星感染 Speakerman
  → 下一关用感染 Speakerman 的声波打断 Cameraman 枪线
  → 联盟部署反寄生枪，建立新的反制目标
```

这一节拍保证玩家先“害怕敌人的能力”，再“夺取敌人的能力”，最后马上遇到对应反制，形成完整的
发现—研究—掌握—被反制循环。

## 7. Alliance 敌军：Cameramen

Cameramen 是 E1 起最早形成组织化防线的联盟主力。他们负责记录、情报共享、科研、常规火力、
反寄生与载具作战。游戏中应当先让玩家学会应对“稳定射击与阵地防守”，再逐步引入特种单位。

### 7.1 量产士兵与职业

| 稳定 ID | 角色/族群 | 原作背景与首次时机 | 威胁行为 | 玩家解法 | 游戏首次投放 |
|---|---|---|---|---|---|
| `camera.normal.v1` | 普通 Cameraman 1.0 | E1 正式抵抗军主体，无声，以手势沟通 | 稳定步枪射击、记录战场 | 冲锋或数量压制 | 1-1 基础敌人 |
| `camera.normal.v2` | 黑色/升级 Cameraman 2.0 | 军备竞赛后普及镜片、耳机和更好武器 | 抗屏幕/声波、喷气机动 | 破甲与集火 | 第二至三章 |
| `camera.normal.v3` | Cameraman 3.0 | E6 逆向 Astro 等离子武器后的新一代 | 等离子卡宾枪、霰弹枪、强化喷气 | 护盾、近身打断 | 第六章 |
| `camera.large.v1` | Large Cameraman | E1 重步兵，能直接压制普通马桶 | 高生命、近战抓取 | 酸液或锯刃破甲 | 第一章精英 |
| `camera.large.v2` | Large Cameraman 2.0 | 中后期武装与防护强化 | 大型枪械、镜片、喷气 | 远程集火 | 第四章 |
| `camera.large.v3` | Large Cameraman 3.0 | E6 新一代重步兵 | Astro 武装、重甲 | EMP/破盾 | 第六章 |
| `camera.heavy_large` | Heavy Large Cameraman | E6 活跃的精英大型个体 | 重火力、近战、协同 G-Squad 抗 Astro | 控制后集中火力 | 第六章友军/挑战敌军，不能继续当主线死敌 |
| `camera.sniper` | Sniper Cameraman | 远程特种兵；3.0 时期有等离子狙击型号 | 标记后排、高伤蓄力 | 装甲分担、突进打断 | 第一章中段，后续换装 |
| `camera.sergeant` | Sergeant Cameraman | 指挥型个体 | 强化附近步兵、调整火力目标 | 优先击杀 | 第一章后段 |
| `camera.samurai` | Samurai Cameraman | 地域化近战特殊个体 | 刀剑突进、格挡 | 爆炸或控制 | 支线精英 |
| `camera.russian` | Russian Cameraman | 社区识别的战斗个体 | 重武器/强硬近战表现 | 远程消耗 | 支线精英 |
| `camera.guard` | Guard/Robert | 基地守卫类个体 | 定点防守、保护入口 | 攻城火力 | 基地关 |
| `camera.medic` | Medic Cameraman | 联盟维修/医疗成员 | 修复受损士兵 | 优先击杀 | 第一章后段 |
| `camera.physician` | Physician Cameraman | 更专业的医疗成员 | 强力单体修复、战损稳定 | 爆发压制 | 第五章 |
| `camera.engineer` | Engineer Cameraman | 为 Titan、载具和设施安装模块 | 修炮塔、架设装置 | 飞行/火箭切后 | 第一章中段 |
| `camera.scientist` | Scientist Cameraman | 研究寄生与马桶技术 | 反寄生枪、技术支援 | 远程优先击杀 | 第二章 |
| `camera.large_scientist` | Large Scientist Cameraman | 操作大型反寄生设备的重型科研成员 | 重型净化、设备保护 | 摧毁设备再攻击本体 | 第三章 |
| `camera.chief_scientist` | Chief Scientist Cameraman | Cameramen 科研领导/高阶成员 | 全局设施强化 | 章节保护目标 | 第五章 |

### 7.2 具名 Cameramen

| 稳定 ID | 角色 | 背景与登场阶段 | 形态/能力 | 敌人设计 | 状态边界 |
|---|---|---|---|---|---|
| `camera.plungerman.v1` | Plungerman / 柱塞侠 | E1 后成为反复出现的莽勇先锋 | 双柱塞、近战突进 | 教会玩家处理高速单体 | 后续升级不能一次性全给 |
| `camera.plungerman.jetpack` | 喷气柱塞侠 | 中期加装喷气背包 | 空中突进、双柱塞 | 飞行刺客精英 | 同一角色正式升级 |
| `camera.plungerman.glitchmobile` | Plungerman + Glitchmobile | E5 使用回收的 Glitch 尸体改造载具 | 极高速冲撞、拳刃 | 多阶段追逐 Boss | 是角色加载具，不是生物融合 |
| `camera.plungerwoman.v1` | Camerawoman | E4 起活跃的敏捷射手，与 Plungerman 关系密切 | 头部/手臂枪械、喷气 | 远程追击精英 | 与普通 Camerawoman 区分 |
| `camera.plungerwoman.v2` | Plungerwoman | E6 继承柱塞象征并获得 Astro 强化 | 引力柱塞、四触手激光、强化喷气 | 高机动复仇型 Boss；E6 后转共同友军 | 原作关系转折后不应继续无理由敌对 |
| `camera.lucky` | Lucky Cameraman | E5 Alpha-Hills 和 Administration 秘密线关键人物 | 瘫痪武器、潜入、隐藏身份关联 | 剧情目标/逃脱者 | 不作普通量产敌人 |
| `camera.detective` | Detective Cameraman | E6 调查 Lucky 与内部秘密 | 追踪、证据分析 | 侦察压制/剧情追踪者 | 不擅自揭晓其调查结论 |
| `camera.scientist_1337` | Scientist Cameraman 1337 | E3 起多次参与前线，重伤后继续作战 | 反寄生、机甲/Strider 驾驶 | 技术型精英、多形态 | 本体、Camera Mech、Strider 是载具切换 |
| `camera.fred` | Fred | 反复出现的大型 Cameraman 个体 | 重步兵能力 | 有辨识度的大型精英 | 具体姓名来源需保留社区/补充确认标记 |
| `camera.1056` | Cameraman 1056 | Alpha-Hills 渗透相关个体 | 常规战斗与小队协作 | 渗透小队成员 | 死亡状态按对应时代处理 |
| `camera.ch4d` | CH4D / 51MP Cameraman | 实验性或特殊镜头个体 | 特殊摄像头能力待完全确认 | 侦察型彩蛋角色 | 未确认能力不做主线门槛 |

### 7.3 Cameramen 载具与构造体

| 稳定 ID | 载具 | 背景 | 战斗功能 | 关卡用途 |
|---|---|---|---|---|
| `camera.drone` | Camera Drone | 侦察、记录、协助充能 | 标记、提高命中 | 基础支援敌人 |
| `camera.battle_drone` | Camera Battle Drone | 后期武装无人机 | 空中射击 | 防空教学 |
| `camera.rover` | Camera Rover | 微型侦察装置 | 暴露隐形/记录 | 潜入关警报器 |
| `camera.strider.v1` | Camera Strider | 联盟多足重火力 | 移动炮台 | 第一章载具精英 |
| `camera.strider.v2` | Camera Strider 2.0 | 后期升级、可由 1337 驾驶 | 等离子重火力 | 第六章精英/共同友军 |
| `camera.parasite_disabler_tank` | 反寄生激光坦克 | 为解除感染研发 | 净化寄生、压制召唤 | 第二至三章关键反制 |
| `camera.paralyzer_tank` | 瘫痪激光坦克 | 控制大型目标的技术 | 短时停机 | 控制型精英 |
| `camera.plasma_tank` | Plasma Camera Tank | E6 Astro 技术换装 | 等离子重炮 | 第六章 |
| `camera.armored_van` | 装甲监控车 | 运输和战斗载具 | 运兵、掩体 | 增援波次 |
| `camera.transport_helicopter` | 运输直升机 | 联盟空运单位 | 投放步兵 | 波次生成器 |
| `camera.attack_helicopter` | 攻击直升机 | 空中火力平台 | 火箭/枪炮 | 防空关 |
| `camera.dropship` | Camera Dropship | 大型空运平台 | 运载重兵 | 章节增援 |
| `camera.orbital` | Orbital Camera | 轨道/重型监控火力装置 | 远程炮击、侦察 | 场景炮击机制 |
| `camera.mech` | Camera Mech | 1337 使用的四臂机械体 | 多武器近远混合 | 第五章多阶段精英 |
| `camera.turret.plasma` | Plasma Camera Turret | 联盟防线固定火力 | 锁定、持续射击 | 城镇结构模块 |

### 7.4 Titan Cameraman

| 稳定 ID | 形态 | 原作时机 | 核心能力 | 游戏投放 |
|---|---|---|---|---|
| `camera.titan.v1` | Titan Cameraman 1.0 | E1 首位联盟 Titan 主力 | 巨力、核心火焰、喷气、手指能量炮 | 第一章幕末不可击败压迫事件 |
| `camera.titan.v2` | Titan Cameraman 2.0 | E4 长期维修后归来 | 轨道炮、机械锤、磁力手、肩炮、护盾、强化核心 | 第四章多阶段 Titan Boss |
| `camera.titan.v2_refined` | 2.1 战地强化 | E4 后续维修与武器增强 | 更强轨道炮、拳刺、护盾 | v2 Boss 二阶段 |
| `camera.titan.buzzsaw_arm` | 锯臂战损形态 | E5 右臂损失后拾取敌方锯臂 | 巨型近战切割 | 战损事件形态，不作永久新人物 |
| `camera.titan.acid_arm` | 酸液臂临时形态 | E5 换装缴获酸液武器 | 腐蚀射击 | Boss 技能模块 |
| `camera.titan.detainer_claw` | Detainer 钳臂形态 | E5 夺取 Astro Detainer 机械钳 | 抓取/约束能量攻击 | E5 终局形态 |

## 8. Alliance 敌军：Speakermen

Speakermen 在 E2 加入 Alliance。他们通过音乐、舞步、声波和近战制造与 Cameramen 完全不同的
压力：不靠稳定枪线，而靠快速接近、击退、范围震荡和节奏增援。

| 稳定 ID | 角色/族群 | 背景与首次时机 | 威胁/能力 | 游戏投放与解法 |
|---|---|---|---|---|
| `speaker.normal.v1` | Normal Speakerman | E2 随大军和阵营音乐登场 | 快速近战、舞步、声波协同 | 第二章基础敌人；用装甲稳住前线 |
| `speaker.normal.v2` | Speakerman 2.0/Armada 士兵 | E6 逆向 Astro 技术后回归 | 等离子武器、强化机动 | 第六章共同友军或挑战单位 |
| `speaker.large.v1` | Large Speakerman | E2 重型近战兵 | 强力击退、范围声波 | 第二章精英；用锯刃和持续恢复 |
| `speaker.large.v2` | Large Speakerman 2.0 | Armada 时期强化 | 重甲、Astro 火力 | 第六章 |
| `speaker.dark` | Dark Speakerman | E5 与 Plungerman 潜入 Alpha-Hills | 双刀/高伤近战、冷酷高效 | 第五章刺客 Boss；原作中牺牲 |
| `speaker.woman` | Speakerwoman | 中后期具名女性战士，参与 Scientist 决战 | 声波、敏捷近战、枪械 | 第五章控制型精英 |
| `speaker.samurai` | Samurai Speakerman | 地域化近战特殊单位 | 刀剑与声波 | 支线精英 |
| `speaker.executioner` | Executioner Speakerman | E6 Armada 的 Semi-Titan 级新单位 | 巨型武器、重型声波、强机动 | 第六章剧情战力，不作地球战争早期敌人 |
| `speaker.scientist` | Scientist Speakerman | 音响阵营科研/维护成员 | 声波设备升级 | 支援敌人 |
| `speaker.maintenance` | 维护型 Speakermen | 不同服装的后勤个体 | 维修、焊接、补给 | 与普通兵归并，作为维修职业 |
| `speaker.strider` | Speaker Strider | 音响重型多足载具 | 大范围声波、移动压制 | 第二章载具 Boss |
| `speaker.van` | Speaker Van | 运输与广播载具 | 增援、范围增益 | 优先摧毁的波次节点 |
| `speaker.helicopter` | Speaker Helicopter | 空中声波/运输平台 | 空投与震荡 | 防空关 |
| `speaker.plane.v2` | Speaker Plane 2.0 | E6 Armada 大型空中平台 | 运兵、Astro 火力 | 第六章场景单位 |
| `speaker.regenerative_ship` | Regenerative Speaker Ship | Armada 支援舰 | 范围修复/恢复 | 第六章优先目标 |
| `speaker.titan.v1` | Titan Speakerman 1.0 | E2 第二位联盟 Titan | 高速飞行、双臂炮、泰坦声波 | 第二章 Titan Boss |
| `speaker.titan.infected` | Infected Titan Speakerman | E2 被大型寄生体控制，E2–E4 为 Skibidi 作战 | 保留泰坦火力并受寄生控制 | 玩家剧情临时友军；不是可制造单位 |
| `speaker.titan.cured` | 治愈后的 Titan Speakerman | E4 被解除感染后重新加入 Alliance | 更成熟的机动与团队协作 | 第四章重新成为敌方 Titan |
| `speaker.titan.upgraded` | 后续升级 Titan Speakerman | E6 处于缺席/升级悬念 | 能力尚未完整公开 | 只预留，不编造技能 |

## 9. Alliance 敌军：TV Men

TV Men 从 E3 正式登场，数量少而技术先进。他们使用屏幕光线、逆向语音、黑烟传送和救援技术。
其玩法重点应是“控制与改变战场位置”，而不是简单增加攻击数值。

| 稳定 ID | 角色/族群 | 背景与首次时机 | 威胁/能力 | 游戏投放与解法 |
|---|---|---|---|---|
| `tv.normal` | Normal TV Man | E3 正式登场的标准成员 | 屏幕控制、灼烧/催眠、黑烟传送 | 第三章基础精英；镜片或音波打断 |
| `tv.dark` | Dark TV Man | 战斗倾向明显的精英个体 | 刀刃、传送、屏幕攻击 | 第五章刺客/控制 Boss |
| `tv.woman.v1` | TV Woman | E3 关键支援者，参与解除 Titan Speakerman 感染 | 可分离头部、传送、屏幕、反寄生 | 第三章支援精英；优先阻止其救援 |
| `tv.woman.v2` | TV Woman 2.0 | 后期强化形态 | 更强武器、传送和近战 | 第五至六章 |
| `tv.large.v1` | Large TV Man / Polycephaly | 多屏重型单位，承担救援和运输 | 多屏控制、大范围传送 | 第三章小型 Boss |
| `tv.large.v2` | Large TV Man 2.0 | E6 后期强化 | Astro 技术、重型战场救援 | 第六章共同友军 |
| `tv.scientist` | Scientist TV Man | TV 阵营科研和战略决策核心 | Astro 逆向研究、基地技术 | 第五章设施保护目标；第六章盟友 |
| `tv.larry` | Larry | 后期战斗型特殊 TV Man | 近战武器、传送 | E6 角色，能力按实际画面更新 |
| `tv.scarf` | Scarf TV Man | 围巾识别的特殊个体 | 战斗/传送 | 支线角色，避免虚构背景 |
| `tv.ceiling` | Ceiling TV | 固定或吊顶式 TV 构造体 | 区域屏幕控制 | 基地陷阱 |
| `tv.titan.v1` | Titan TV Man / Cinemaman | E3 第三位联盟 Titan；可挂载音响形成 Cinemaman 战斗配置 | 多屏控制、传送、核心、近战 | 第三章 Titan Boss |
| `tv.titan.v2` | Upgraded Titan TV Man | E5 重返战场的强化形态 | 能量刃、护盾、肩屏/分离屏幕、传送、回收武器 | 第五章终局 Titan |
| `tv.watchman_of_doom` | Watchman of Doom | E6 被 Astro Core Penetrator 控制后的 Titan TV Man | Doom Cannon、Astro 护盾、受控攻击 | 第六章共同敌人；目标应偏向解除控制而非处决 |

## 10. 后期共同敌人：Astro Toilets

Astro 不属于前五章“马桶人攻联盟”的敌我结构。E6 后地球 Skibidi 与 Alliance 已被迫局部合作，
此时 Astro 才接管主敌位置。

| 稳定 ID | 单位 | 背景/层级 | 战斗功能 | 建议投放 |
|---|---|---|---|---|
| `astro.trooper` | Trooper Astro Toilet | 无条纹或低阶步兵 | 曲速突入、等离子射击 | 第六章基础兵 |
| `astro.specialist` | Specialist Astro Toilet | 隐形/特种重步兵 | 潜行、近距离压制 | 侦察反制教学 |
| `astro.interceptor` | Interceptor Astro Toilet | 快速战斗机单位 | 高速空战、持续存活能力 | 第六章飞行精英 |
| `astro.strider` | Strider Astro Toilet | 轻型多足/悬浮装甲单位 | 地面推进 | 中型精英 |
| `astro.impactor` | Impactor Astro Toilet | 重型轨道/冲击单位 | 砸落、范围冲击 | 重装 Boss |
| `astro.destructor` | Destructor Astro Toilet | 重武装主力 | 核心能量、重炮 | 波次精英 |
| `astro.obliterator` | Obliterator Astro Toilet | 轰炸与运输重型单位 | 范围毁灭、携带单位 | 小型 Boss |
| `astro.annihilator` | Annihilator Astro Toilet | 更高火力的毁灭单位 | 战区级轰炸 | 后期 Boss |
| `astro.carrier` | Carrier Astro Toilet | 舰载和城市毁灭平台 | 部署 Interceptor/Core Penetrator、护盾 | 章节 Boss |
| `astro.rocketeer` | Rocketeer Astro Toilet | 早期出现并在后续归类的轰炸单位 | 高速火箭攻击 | 过渡精英 |
| `astro.assailant` | Assailant/UFO Astro Toilet | 高阶指挥者，军衔权威高 | 曲速、指挥、远程攻击 | 第六章统帅 Boss |
| `astro.detainer` | Detainer Astro Toilet | 执行与拘捕型精英 | 巨钳抓取、缴械、反投射物 | 多阶段控制 Boss |
| `astro.juggernaut` | Juggernaut Astro Toilet | 舰队主战重装个体 | 正面压制 Titan、能量盾/重击 | Titan 级 Boss |
| `astro.duchess` | Duchess Astro Toilet | 高阶贵族和战斗指挥者 | 护盾、能量触手/鞭、泰坦级压制 | 赛季统帅 |
| `astro.hunter_mutant` | Hunter Astro Mutant | 高速猎杀型人形 Astro | 单目标追杀 | 后排猎手 |
| `astro.scout` | Scout Astro Toilet | 较小型特殊个体 | 侦察、高速突击 | 剧情精英 |
| `astro.core_penetrator` | Core Penetrator | 控制 Titan 核心的构造体 | 附着、劫持、声波压制 | 必须优先摧毁的 Boss 机制 |
| `astro.mothership` | Mothership Astro Toilet | 巨型舰队基地与战略资产；未确认是最高领袖 | 城市级毁灭、运载 | 场景目标，不做常规可抽角色 |
| `astro.duke` | Duke Astro Toilet | 已知更高阶贵族线索 | 能力未完整展示 | 只作伏笔，不编造战斗数据 |

## 11. 隐藏阵营与非战斗角色

| 稳定 ID | 角色/阵营 | 背景 | 游戏用途 | 边界 |
|---|---|---|---|---|
| `admin.secret_agent` | Secret Agent / Administrator | Alpha-Hills 和多场事件背后的干预者，帮助、操控并清除知情者 | 长期悬念、隐藏任务、结算异常 | 不在第一幕解释完整动机 |
| `admin.agents` | Administration 成员 | 与 Lucky、绿色西装 Cameramen 等秘密线有关 | 潜伏、证据、阵营反转 | 身份未确认时使用 `未知` |
| `human.survivor` | 人类幸存者 | 早期世界崩溃后的少量幸存者 | 护送、环境叙事 | 不作为基础战斗阵营 |
| `human.alpha_hills_staff` | Alpha-Hills 人员 | 与实验设施过去有关 | 日志、录像、回忆 | 不擅自确定转化真相 |

## 12. 同一角色的升级与独立单位判定

| 关系 | 正确处理 | 例子 |
|---|---|---|
| 同一角色的正式重构 | 独立形态，共享角色身份与剧情解锁 | G-Toilet v1→v4、Titan Cameraman 1.0→2.0 |
| 临时拾取武器 | 技能模块或战斗皮肤，不新建人物 | Titan Cameraman 锯臂、酸液臂、Detainer 钳 |
| 驾驶载具 | 角色与载具组合形态 | Plungerman + Glitchmobile、1337 + Camera Mech |
| 被寄生/劫持 | 独立剧情状态，拥有阵营和技能变化 | Infected Titan Speakerman、Watchman of Doom |
| 克隆或诱饵 | 独立单位，不算本尊升级 | G-Clone、Decoy G-Toilet |
| 同族不同个体 | 共享原型，可产生多个英雄实例 | Normal Toilet、Cameraman、Large Speakerman |
| 只有服装或轻微战损不同 | 外观/状态，不建立新科技节点 | 不同领带 Cameramen、破损镜片 |

## 13. 推荐章节投放

| 章节 | 玩家新友军 | 新敌军 | Boss/剧情压迫 | 玩家本章应理解 |
|---|---|---|---|---|
| 序章 E0 | G-Toilet v1、普通、冲锋 | 人类环境、零散 Cameramen | 城市防线 | 马桶军团从异常事件变成战争 |
| 第一章 E1 | 装甲、火箭、Large、Engineer | Cameraman 1.0、Large、Drone、Strider、Engineer | Titan Cameraman 1.0 | 联盟拥有组织化枪线和防御设施 |
| 第二章 E2 | DJ v1、Jetpack、Parasite、感染 Camera/Speaker 宿主 | Normal/Large Speakerman、Speaker Van/Strider | Titan Speakerman → 感染反转 | 声波、寄生研发与宿主科技树形成第一条完整克制链 |
| 第三章 E3 | Glitch、寄生母体、激光 Strider | TV Man、TV Woman、Large TV、反寄生坦克 | Titan TV Man/Cinemaman | 镜片、屏幕、传送和净化改变战局 |
| 第四章 E4 | G-Toilet v3、酸液、多联火箭、G-Clone | Cameraman 2.0、救援部队、治愈 Titan Speakerman | Titan Cameraman 2.0 | 单靠稀有度无法越过联盟技术反制 |
| 第五章 E5 | Scientist Mech、Berserker、Buzzsaw、SWAT、维修队 | 渗透小队、Plungerman、Dark Speakerman、Titan TV Man 2.0 | Alpha-Hills 决战 | 玩家在保卫研发体系，同时失去重要领袖 |
| 第六章 E6 | G-Squad 后期形态、G-Toilet v4/v5 | Astro 全梯度 | Juggernaut、Duchess、Watchman | 旧敌必须合作，真正的战略威胁来自太空 |

## 14. 游戏角色数据建议字段

后续将本文落成 Resource 或表格时，每个角色至少保存：

```text
stable_id
display_name_zh
display_name_en
faction
subfaction
continuity
canon_confidence
name_source
story_era_first
episode_first_reference
story_status_by_era
form_of
upgrade_from
host_source_id
parasite_compatibility
parasite_research_node
sync_rank
role_tags
movement_tags
counter_tags
game_side_by_era
recommended_unlock
production_priority
legal_or_asset_risk
notes
```

`game_side_by_era` 必须是按时代映射，不能只存一个永久敌我布尔值。至少支持：

```text
E0-E5: Skibidi=player, Alliance=enemy
E6: Skibidi=player, Alliance=temporary_ally, Astro=enemy
```

## 15. 制作优先级

### P0：当前可玩闭环

- G-Toilet 早期形态；
- 冲锋、装甲、音波、火箭飞行、自爆飞行、双锯、维修、寄生母体八个现有原型；
- Cameraman 普通兵、大型兵、工程师、无人机、炮塔；
- Titan Cameraman 只制作幕末压迫演出所需轮廓。

### P1：第一至三章辨识度

- DJ v1、Jetpack、Laser Strider、普通寄生体；
- 感染 Cameraman、感染 Large Cameraman、感染 Speakerman；
- Normal/Large Speakerman、Speaker Strider；
- Normal/TV Woman/Large TV Man；
- 反寄生坦克、Plungerman。

### P2：Alpha-Hills 核心收藏

- G-Toilet v3/v4、Chief Scientist Mech；
- Berserker、Buzzsaw、SWAT；
- Plungerman + Glitchmobile、Dark Speakerman、Titan TV Man 2.0。

### P3：Astro 赛季

- G-Squad 后期升级；
- Astro Trooper、Specialist、Interceptor、Destructor；
- Carrier、Detainer、Juggernaut、Duchess、Watchman of Doom。

## 16. 验收标准

- 每个进入制作排期的角色都能追溯到本文条目和来源标签。
- 每个角色至少拥有一个一眼可见的职责、一个优势和一个反制点。
- 正式升级、临时装备、载具组合、感染状态、克隆和外观皮肤不互相混淆。
- 前五章 Alliance 是防守敌军；E6 后敌我变化必须由剧情事件明确呈现。
- 不因收藏稀有度让普通角色失去关卡价值。
- 不把社区名称、推断或游戏原创职位写成官方事实。
- 不使用同人宇宙角色填补原作空缺。
- 每个感染宿主必须先以敌人身份展示其能力，再允许玩家研究；TV、Titan 和载具遵守兼容性限制。
- 感染宿主是永久组合角色，不能要求玩家持续消耗俘虏，也不能随机背叛破坏确定性战斗。
- 新增官方内容时，先更新时代、状态和阵营关系，再决定是否进入游戏。

## 17. 资料入口

- [官方 Skibidi YouTube 频道](https://www.youtube.com/@skibidi)
- [原作世界观研究](skibidi-toilet-lore-research.md)
- [第一幕可制作角色名册](earth-war-character-roster.md)
- [Skibidi Toilets 角色索引](https://skibidi-toilet.fandom.com/wiki/Category%3ASkibidi_Toilets)
- [Cameramen 阵营索引](https://skibidi-toilet.fandom.com/wiki/Cameraman)
- [Speakermen 阵营索引](https://skibidi-toilet.fandom.com/wiki/Speakerman)
- [TV Men 阵营索引](https://skibidi-toilet.fandom.com/wiki/TV_Man)
- [Astro Toilets 阵营索引](https://skibidi-toilet.fandom.com/wiki/Astro_Toilet)

社区 Wiki 用于定位角色与集数，不视为与官方发布同等级的最终证据。进入模型、宣传或商业发布前，
仍需回看原集画面，并审查 Source/Valve 模型、真人肖像、音乐和粉丝内容授权风险。

## 相关节点

[KM:reference.skibidi-toilet-lore-research](skibidi-toilet-lore-research.md)、
[KM:reference.earth-war-character-roster](earth-war-character-roster.md)、
[KM:reference.skibidi-toilet-idle-siege-gdd](skibidi-toilet-idle-siege-gdd.md)。
