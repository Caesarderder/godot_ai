---
km_id: reference.skibidi-toilet-lore-research
km_type: reference
domain: product
status: active
owner: product-design
last_verified: 2026-07-29
source_of_truth:
  - docs/references/product-design/skibidi-toilet-lore-research.md
validated_by:
  - external-source-cross-check-2026-07-23
  - manual-canon-boundary-review
  - python3 tools/docs_lint.py
tags:
  - domain:product
  - reference:lore
  - risk:canon-drift
related:
  - domain.product
  - reference.skibidi-toilet-idle-siege-gdd
---

# Skibidi Toilet 世界观、故事线与角色研究

## 目标

为《马桶人进化-维度爆裂》的关卡、角色、稀有度、技能和内容更新提供统一的原作依据。本节点优先回答：

- 哪些阵营在什么时期互为敌友；
- 主要故事阶段发生了什么；
- 哪些角色适合进入生产、编队、Boss 或剧情系统；
- 哪些名称、状态或设定仍存在社区推断，不能写成确定正史；
- 游戏怎样使用原作素材而不制造明显的时间线矛盾。

## 研究口径

### 正史基线

截至 2026-07-23，本项目采用以下优先级：

1. [官方 Skibidi YouTube 频道](https://www.youtube.com/@skibidi)发布的原编号系列；
2. 原编号系列的 season compilation、additional scenes 和官方描述；
3. 官方衍生系列 `Skibidi Toilet: Emergence`，但与原编号系列分层记录；
4. [Skibidi Toilet Wiki](https://skibidi-toilet.fandom.com/wiki/Skibidi_Toilet_series)的逐集整理，用于定位情节和社区通用名称；
5. [Wikipedia 故事摘要](https://en.wikipedia.org/wiki/Skibidi_Toilet)等二级来源，只用于交叉验证宏观故事。

原编号系列 `1–79` 是当前游戏最稳定的剧情基线。`Skibidi Toilet: Emergence` 于 2025-10-26推出第一集，属于官方衍生内容，但制作方式、叙事语气和社区接受度与原编号系列存在差异；在开发者另行确认前，不把 `Emergence` 独有设定写入首版角色或关卡。

### 事实标签

- **原作明确**：画面、官方描述或多处剧情直接支持。
- **社区通用**：Wiki 和社区长期采用，但可能不是官方正式命名。
- **推断**：由画面、文件或对白推测，后续可能被新剧情推翻。
- **游戏改编**：为了玩法清晰而提出，不宣称属于原作正史。

### 持续更新规则

这是一个会随新集数变化的活跃节点。新增角色、死亡状态、阵营关系和进化形态前，必须重新检查最新官方内容；不能只看短视频剪辑、同人动画或角色强度榜。

### 当前 60 关采用的逐集硬边界

本轮仅把 Wiki 可定位的事件写入玩家剧情；不确定的过渡关使用“双方交战”等中性标题，不补地点、
组织或人物动机。必须遵守以下易错点：

- E18 为 Titan Cameraman 登场，E20 为第一次泰坦级交战；
- E24 为 Speakermen 登场，E26 为 Titan Speakerman 登场，E29 为 Glitch；
- E28 是 Titan Speakerman 袭击 Skibidi 会议，不写成 Scientist 的寄生行动；
- E31 是普通 Speakerman 被感染，Titan Speakerman 在 E32 才被大型寄生体控制；
- E47 包含 Cinemaman、G-Toilet 与 Infected Titan Speakerman 的战斗；
- E50 为升级 Titan Cameraman 回归，E57 为 Titan Speakerman 解除感染；
- E66–E74 是 Alpha-Hills 至 Astro 舰队来袭阶段；E70 Chief Scientist 死亡，E71 G-Squad，
  E72 G-Toilet 对 Detainer，E73 三 Titan 对 G-Toilet，E74 Astro 舰队来袭；
- E74 只作本幕尾声，不能倒推成更早章节里 Alliance 与地球 Skibidi 已经结盟。

角色显示名使用 [原作角色百科](original-series-character-codex.md) 中的 `原作明确` 或可核查族群。
`Normal`、`Armored`、`Rocketeer`、`Large Parasitic` 等是族群原型，不给随机生成个体补写姓名或生平；
`plunger_charge`、时间冻结、团队护盾等保留的技能 ID 是兼容性与玩法实现，说明必须标注“玩法改编”。

## 世界观总览

### 世界状态

故事发生在被持续战争摧毁的现代城市与地下设施中。早期 Skibidi Toilets 快速压倒人类，随后由 Cameramen、Speakermen 和 TV Men 组成的 Alliance 进行抵抗。双方不断夺取、复制、升级对方技术，战争从街头冲突升级为巨型 Titan、寄生控制、地下实验室、传送技术和外星舰队参与的军备竞赛。

这个世界不是固定职业制，而是“**基础族群 + 体型层级 + 武器改造 + 版本升级**”：

- 同一族群可出现 normal、large、giant、semi-titan、titan 等体型；
- 同一角色会随着剧情获得 `1.0 / 2.0 / 3.0` 等装备形态；
- 武器、护甲、飞行和反制设备经常被双方复制；
- 强度不只来自体型，也来自机动、射程、屏幕效果、声波、寄生、传送和防护装备；
- 战斗结果经常改变角色状态，形成受伤、升级、感染、治愈、阵亡或失踪。

这与 GDD 已确认的“角色固定稀有度、不同进化形态作为独立角色”天然兼容。

### 基础战斗语法

| 原作机制 | 原作表现 | 游戏可用语义 |
|---|---|---|
| 冲水与头部弱点 | 早期普通马桶可通过冲水或直接破坏头部击败 | 普通单位的低耐久或处决反馈，不应成为所有高阶角色的统一弱点 |
| 体型层级 | normal、large、giant、titan 形成清晰压迫差 | 车间成本、占位、生命和击退抗性 |
| 激光与火箭 | 中后期主要远程武器 | 直线输出、范围轰炸、防御设施破坏 |
| Jetpack / 飞行 | 绕开地面阻挡并快速切入 | 飞行车间和后排突袭 |
| Strider / 机械足 | 提高移动与地形适应能力 | 高机动远程或攻城单位 |
| 声波 | Speakermen、DJ Toilet 等可击退、干扰或偏转攻击 | 击退、打断、短时防护 |
| TV 屏幕 | 催眠、灼烧、死亡屏幕等效果；镜片可形成反制 | 控制、持续伤害与“是否装备镜片”的克制 |
| 耳机 | 抵御声波影响 | 对声波控制的被动抗性 |
| 寄生控制 | Parasite Toilets 可控制 Alliance 成员，Titan Speakerman 曾被感染 | 临时召唤、短时夺取敌人或特殊剧情关卡 |
| 传送与 Warp | TV Men 使用烟雾传送；Astro Toilets 使用高速 Warp | 切后排、撤退、阶段转场 |
| 技术回收 | 双方回收敌方残骸并逆向升级 | 蓝图掉落、角色新形态解锁 |

## 阵营与关系

### Skibidi Toilets

**原作明确：** 由人类头部与马桶或其他设施结合的战斗族群，早期以征服地球为目标，由 G-Toilet 领导，Chief Scientist Skibidi Toilet 负责研发和升级。后期发展出飞行、激光、火箭、Strider、Mutant、寄生、维修和大规模机械单位。

主要内部结构：

- **领导与研发**：G-Toilet、Chief Scientist Skibidi Toilet；
- **基础军团**：Normal、Medium、Large、Giant 等体型；
- **机动军团**：Flying、Jetpack、Helicopter；
- **攻城军团**：Laser、Rocket、Strider、Wheeler、重装单位；
- **特殊单位**：DJ、Glitch、Parasite、Scientist、Repairer；
- **Skibidi Mutants**：使用人形身体、拥有近战武器和更强战术能力；
- **G-Squad**：围绕 G-Toilet 行动的具名精英单位。

### The Alliance

Alliance 由三个主要硬件头族群组成：[Cameramen、Speakermen 和 TV Men](https://skibidi-toilet.fandom.com/wiki/The_Alliance)。

| 子阵营 | 核心特征 | 代表战斗语义 |
|---|---|---|
| Cameramen | 数量最多，负责观察、记录、科研和通用战斗 | 平衡型步兵、狙击、载具、瘫痪武器 |
| Speakermen | 使用音乐、舞蹈和声波，近战倾向明显 | 击退、范围声波、突进 |
| TV Men | 数量少、技术先进，使用屏幕和烟雾传送 | 控制、灼烧、传送、技术回收 |

三个子阵营分别拥有 Titan Cameraman、Titan Speakerman 和 Titan TV Man。Alliance 并非始终意见一致：TV Men 多次表现出更强的技术优先和保密倾向，Cameramen 承担大量前线伤亡，Speakermen 则在 Titan 被感染后遭受重创。

### Astro Toilets

**原作明确：** Astro Toilets 是拥有远超地球阵营技术的外星马桶势力，使用高速 Warp、反重力、能量护盾和大规模舰队。G-Toilet 曾是 Astro 指挥官，后来与其决裂。Astro 的到来迫使 Skibidi 与 Alliance 暂时合作。

[Astro 阶级](https://skibidi-toilet.fandom.com/wiki/Astro_Toilet)带有军事和贵族式结构，头盔条纹通常表示权力层级，但不直接等同于个人战斗力。已知高阶存在包括 Duchess、Duke、Assailant、Mothership 等，真正最高领导者仍未明确。

### The Administration

以 Secret Agent / Administrator 为核心的神秘势力，与 Alpha-Hills Labs 和部分 Cameramen 有联系。其目标并未公开，既帮助过 Alliance，也操控证据、招募成员并清除知情者。它是“世界真相”层面的长期悬念，不适合在首个休闲放置版本中一次解释完。

### Humans

早期人类社会很快被战争压倒，但后续剧情显示仍有少量人类、军事人员和 Alpha-Hills 历史记录存在。人类不是首版生产阵营，但可以作为环境叙事、幸存者目标或世界毁灭程度的参照。

### 阵营关系时间线

```text
早期：
Skibidi Toilets  vs  Humans / Cameramen

联盟形成：
Skibidi Toilets  vs  Cameramen + Speakermen + TV Men

Astro 入侵后：
Astro Toilets  vs  Skibidi Toilets + Alliance（脆弱的临时合作）

隐藏线：
The Administration 观察、干预并保护自身秘密
```

## 故事线

以下阶段名称是为了游戏策划整理的编辑性命名，不是官方章名。

### 阶段一：异常爆发与城市沦陷（Episode 1–6）

- Skibidi Toilet 从荒诞短片式事件迅速扩展为群体现象；
- 普通人类面对会唱歌、移动和攻击的厕所怪物；
- 世界规则尚未完整解释，重点是突发、怪异和快速升级。

**游戏价值：** 最适合作为教学序章。单位少、街区小、敌人弱，能够先建立“生产马桶人并占领城市”的直接目标。

### 阶段二：Cameramen 抵抗与 G-Toilet 登场（Episode 7–20）

- Cameramen 形成有组织的抵抗；
- G-Toilet 作为 Skibidi 领导者出现；
- Titan Cameraman 加入战场，巨型单位把冲突升级为正式战争；
- 双方开始通过体型、武器和战术升级取得短期优势。

**游戏价值：** 对应第一章主体。敌人从普通 Cameraman 升级到 Large、载具、防御设施和 Titan Cameraman Boss。

### 阶段三：Speakermen 加入与寄生反转（Episode 21–32）

- Speakermen 加入 Alliance，声波与近战改变战场；
- Titan Speakerman 成为 Alliance 新的 Titan 战力；
- Chief Scientist 研发的寄生单位成功控制 Titan Speakerman；
- Skibidi 借敌方 Titan 之力重创 Alliance。

**游戏价值：** 解锁特殊车间、Parasite 配方和“暂时控制敌方单位”玩法。感染 Titan Speakerman 可作为章节高潮，但应明确属于剧情态而非常规永久生产。

### 阶段四：感染统治、TV Men 与军备竞赛（Episode 33–49）

- 被感染的 Titan Speakerman 持续为 Skibidi 作战；
- TV Men 与 Titan TV Man / Cinemaman 加入；
- 镜片、耳机、屏幕、声波、寄生与反寄生形成多层克制；
- G-Toilet、Titan 与精英单位持续升级，战争进入反制链条。

**游戏价值：** 适合引入装备式被动、控制免疫和多阶段 Boss。不能只用“战力数字”表达这一时期。

### 阶段五：Titan Cameraman 归来与 Titan Speakerman 获救（Episode 50–57）

- 升级后的 Titan Cameraman 重返前线；
- Alliance 使用瘫痪和反寄生技术寻找解救机会；
- Episode 57 中 Titan Speakerman 被成功解除控制；
- G-Toilet 遭受重创并撤退。

**游戏价值：** 这是天然的失败节点。玩家作为 Skibidi 方可以经历一次必败或高难关卡，随后回厂解锁重装、诱饵和新 G-Toilet 形态。

### 阶段六：Scientist、Mutants 与 Alpha-Hills 攻防（Episode 58–74）

- Chief Scientist 的大型 Mech、Skibidi Mutants 和更多实验单位登场；
- Alliance 发起对 Alpha-Hills Labs 的渗透与围攻；
- Plungerman、Dark Speakerman 等深入设施；
- Chief Scientist 被击杀，Plungerman 和 Dark Speakerman 也死亡；
- Secret Agent / Administrator 的干预与 Alpha-Hills 历史浮出水面；
- G-Toilet 与 Astro 的旧关系开始影响主战局。

[Alpha-Hills Siege](https://skibidi-toilet.fandom.com/wiki/The_Siege_of_Alpha-Hills)覆盖 Episode 66–74，是原作最适合改编为连续关卡的一段：外部防线、地下设施、实验区、精英追杀和核心 Boss 都有明确空间层次。

**游戏价值：** 对应中期高内容密度章节。工厂配方可由“Scientist 蓝图”驱动，Mutants 进入重装和特殊车间，Alliance 则拥有更完整的反制装备。

### 阶段七：Astro 入侵与被迫停战（Episode 74–77）

- Astro Toilets 以压倒性技术进入地球战场；
- Alliance 与 Skibidi 单独都无法抵抗；
- 两个旧敌开始在局部战场共同对抗 Astro；
- Titan TV Man 对停战持强烈怀疑，但仍投入救援；
- Episode 77 结尾，Titan TV Man 被 Astro 的 Core Penetrator 控制，成为 Watchman of Doom。

**游戏价值：** 这是主战役阵营关系的转折点。进入该阶段后，再让 Skibidi 无理由持续攻击 Alliance 会违反原作当前关系；应改为 Astro 防御战、临时混编或平行挑战模式。

### 阶段八：反攻、基地失守与 Watchman of Doom（Episode 78–79）

- Skibidi Mutants 与 Alliance 继续协同抵抗 Astro；
- 双方尝试回收并利用 Astro 技术；
- Watchman of Doom 攻击 Cameramen Headquarters；
- Cameramen 基地遭到毁灭性打击，幸存者撤退；
- Astro 仍保持战略优势，原编号系列主线尚未结束。

**游戏价值：** 适合作为后期赛季内容。Watchman of Doom 是极强章节 Boss，也可以建立“救回 Titan TV Man”的长期目标。

### Emergence 分支

`Skibidi Toilet: Emergence 1`的官方描述是围绕 Lucky Cameraman 的信号、Alliance 与 Astro 对一个长期秘密的争夺，并继续使用 Alpha-Hills、Secret Agent、Astro 和 Skibidi 角色。它是官方衍生系列，而不是简单的编号 Episode 80。

**当前处理：** 首版只保留为未来资料源，不把其独有设计、能力或时间线写入基础配方。若后续采用，必须在 GDD 中明确是“原编号主线延续”还是“Emergence 赛季”。

## 核心角色

### Skibidi 阵营领导与传奇角色

| 角色 | 原作位置 | 标志能力或特征 | 游戏定位建议 | 状态注意 |
|---|---|---|---|---|
| G-Toilet | Skibidi 领导者、前 Astro 指挥官 | 多阶段武装升级、激光、喷射机动、指挥和战术撤退 | 传说级攻城核心；不同版本独立角色 | 不同形态必须绑定对应剧情阶段 |
| Chief Scientist Skibidi Toilet | 二号人物与研发核心 | 寄生技术、Mech、激光、实验设施、单位升级 | 传说级召唤/控制/工厂加速核心 | Episode 70 后本人死亡；后续 Mech 或记录需区分 |
| DJ Skibidi Toilet | G-Squad 具名成员 | 声波、扬声器、攻击偏转、后期机械形态 | 史诗或传说辅助，提供击退和团队增益 | 早期与升级形态差异很大 |
| Glitch Skibidi Toilet | 高速特殊单位 | Sonic Charge、超高速撞击 | 史诗刺客，瞬间切入后排 | 本体死亡后被改造成 Glitchmobile，不应在后期剧情无解释复活 |
| Decoy / G-Clones | G-Toilet 的诱饵和仿制单位 | 模拟首领外形、不同武装组合 | 史诗攻城或首领替代品 | 必须与真正 G-Toilet 清晰区分 |

### Skibidi 基础与生产单位

| 生产族群 | 代表角色 | 适合车间 | 游戏功能 |
|---|---|---|---|
| Base Toilets | Normal、Medium、Large、Giant | 普通 / 重装 | 低成本前排、数量流、体型成长 |
| Flying / Jetpack | Flying、Jetpack、Helicopter | 飞行 | 绕开地面、切后排、空袭 |
| Strider | Armed、Laser、Launcher Strider | 飞行 / 重装 | 高机动远程与设施破坏 |
| Laser / Rocket | Quad-Laser、Rocketeer、Artillerist | 重装 | 直线爆发、范围轰炸 |
| Scientist / Repair | Scientist、Engineer、Repairer、Welder | 特殊 | 充能、修复、召唤设备 |
| Parasite | Normal、Large、Helicopter Parasite | 特殊 | 短时控制、感染剧情 |

### Skibidi Mutants 与 G-Squad

[Skibidi Mutants](https://skibidi-toilet.fandom.com/wiki/Skibidi_Mutant)使用人形身体和近战武器，具有更强的个体人格与战术能力。它们比普通马桶更适合作为“稀有角色”。

| 角色 | 识别点 | 游戏定位建议 |
|---|---|---|
| Berserker Skibidi Mutant | 巨型体格、近战撕裂、后期肩炮与钩爪 | 重装前排、冲锋、嘲讽或破甲 |
| Buzzsaw Skibidi Mutant | 标志性锯刃、后期 Astro 激光与 EMP | 史诗战士，持续近战与短时眩晕 |
| SWAT Skibidi Mutant | 能量镰刀、火箭、战术作战 | 近远混合输出 |
| Mafia Skibidi Mutant | Semi-Titan 级身体 | 高成本重装或小型 Boss |
| Female / Heroine Skibidi Mutant | 激光、爪和独特身体 | 高机动精英输出 |
| Michael Jackson Skibidi Toilet | 高识别度具名成员 | 活动或剧情角色；公开素材使用前需单独审查第三方肖像与音乐风险 |

### Alliance Titan

| 角色 | 故事作用 | 核心能力 | Boss 设计价值 |
|---|---|---|---|
| Titan Cameraman | Alliance 最早的 Titan 主力 | 重装、核心能量、火力与近战 | 教学后的首个巨型 Boss；突出护甲和正面压制 |
| Titan Speakerman | 声波 Titan，曾被寄生控制 | 高机动、声波、双臂武器 | 可经历敌方 Boss → 受控友军 → 被治愈敌人的状态变化 |
| Titan TV Man / Cinemaman | TV Men Titan | 屏幕控制、传送、近战、后期护盾与回收武器 | 多阶段控制 Boss，需要镜片、耳机和技能打断 |
| Watchman of Doom | 被 Astro 控制的 Titan TV Man | Astro 核心控制、Doom Cannon、护盾 | 后期大型 Boss，与普通 Titan TV Man 必须分开 |

### Alliance 具名角色

| 角色 | 阵营 | 故事作用 | 游戏用途 |
|---|---|---|---|
| Plungerman | Cameramen | 渗透先锋，与 Alpha-Hills、Glitchmobile 和 Secret Agent 线相关 | 精英刺客 Boss；高机动、连续突击 |
| Camerawoman / Plungerwoman | Cameramen | 远程战斗、与 Plungerman 有强关系线 | 远程精英、复仇或追击关卡 |
| Dark Speakerman | Speakermen | Alpha-Hills 渗透成员，与 Plungerman 并肩作战 | 高伤近战精英 |
| Speakerwoman | Speakermen | 具名女性战士，参与 Scientist 决战 | 声波控制与近战组合 |
| TV Woman | TV Men | 传送、救援、反寄生 | 支援型精英，能撤走受伤目标 |
| Large TV Man / Polycephaly | TV Men | 重型屏幕单位、传送和战场救援 | 重装控制 Boss |
| Scientist TV Man | TV Men | 逆向研究 Astro 技术与战略决策 | 设施保护目标或技术型 Boss |
| Lucky Cameraman | Cameramen / Administration 关联 | Alpha-Hills 与 Secret Agent 秘密线关键角色 | 剧情目标，不宜首版当普通量产敌人 |
| Detective Cameraman | Cameramen | 调查内部秘密和 Lucky Cameraman | 剧情追踪者或精英敌人 |

### Astro 关键角色与兵种

| 角色或兵种 | 层级与作用 | 游戏定位建议 |
|---|---|---|
| Duchess Astro Toilet | 高阶指挥官 | 章节统帅、远程压制与剧情 Boss |
| Assailant Astro Toilet | 高阶指挥与侦察存在 | 高机动指挥 Boss |
| Juggernaut Astro Toilet | 超重型战斗个体 | 正面压制 Titan 的重装 Boss |
| Detainer Astro Toilet | 使用大型机械爪 | 抓取、缴械、控制型 Boss |
| Mothership Astro Toilet | 巨型舰队资产，不是已确认最高领袖 | 场景级终局目标，不作为常规角色 |
| Carrier Astro Toilet | 运送部队和 Core Penetrator | 召唤与增援型 Boss |
| Obliterator / Destructor | 主力重型单位 | 后期精英波次和范围火力 |
| Interceptor / Specialist / Trooper | 中小型 Astro 单位 | 构成后期基础敌军梯度 |
| Core Penetrator | 控制 Titan TV Man 的装置 | Boss 阶段机制或需要优先摧毁的目标 |

## 角色命名与形态规则

### 名称来源

角色名称存在三种来源：

1. 官方标题、描述、对白或正式出版物明确给出的名称；
2. 创作者在问答或补充材料中确认的名称；
3. 社区为了识别角色建立的描述性名称。

知识地图和游戏数据应为每个角色保存：

```text
stable_id
display_name_zh
display_name_en
name_source
faction
story_era
form_version
canon_status
```

如果名称仅为社区通用，`name_source` 必须记录为 `community`，不要在宣传材料中声称是官方正式名。

### 形态不是皮肤

在本游戏中，原作的重要形态变化应成为独立角色定义，而不是只换外观：

- G-Toilet 的不同武装阶段；
- Chief Scientist 本体与 Scientist Mech；
- Titan Speakerman、Infected Titan Speakerman 和治愈后的升级形态；
- Titan TV Man、升级 Titan TV Man 和 Watchman of Doom；
- Buzzsaw / Berserker 等 Mutant 的主要升级阶段。

每个形态需要独立的故事时期、稀有度、技能和模型来源。只有不改变能力的轻微损伤、颜色或装饰变化才适合作为皮肤。

## 对 GDD 的直接约束

### 推荐的主战役时间结构

为了同时保留“玩家率领 Skibidi 攻打 Alliance”和后期 Astro 故事，建议采用按时代展开的章节：

| 游戏章节 | 原作时期 | 玩家主要敌人 | 系统解锁 |
|---|---|---|---|
| 序章：城市感染 | Episode 1–6 | Humans、早期 Cameramen | 普通车间、基础合成 |
| 第一章：镜头反击 | Episode 7–20 | Cameramen、Titan Cameraman | 重装车间、攻城设施 |
| 第二章：声波战争 | Episode 21–32 | Speakermen、Titan Speakerman | 飞行车间、声波抗性 |
| 第三章：寄生统治 | Episode 33–49 | Alliance 三族、Titan TV Man | 特殊车间、寄生和控制 |
| 第四章：Titan 反攻 | Episode 50–57 | 升级 Titan Cameraman、救援部队 | 高阶 G-Toilet 与诱饵 |
| 第五章：Alpha-Hills | Episode 58–74 | 渗透小队、Alliance Titan | Mutant、Scientist Mech、实验配方 |
| 第六章：Astro 入侵 | Episode 74–79 | Astro Toilets | 临时联盟、Astro 蓝图、Watchman Boss |

这允许前五章保持 Skibidi 对 Alliance 的攻城结构；第六章再明确改变阵营关系。若首版只做一个内容切片，应从第一章或第二章取材，而不是直接放在 Episode 77 之后。

### 工厂叙事解释

GDD 中的四类车间可以由 Chief Scientist 的研发体系解释：

- 普通车间：标准体型与批量基础单位；
- 飞行车间：Jetpack、Helicopter、Flying 和 Strider；
- 重装车间：Large、Giant、Laser、Rocket、攻城机械；
- 特殊车间：Parasite、Scientist、DJ、Glitch、Mutant 和具名配方。

玩家取得新配方的主要来源应是：

- 剧情推进得到 Scientist 蓝图；
- 回收 Alliance 或 Astro 残骸完成逆向研究；
- 击败具名 Boss 解锁对应反制配方；
- 完成时代章节解锁该时期的角色形态。

### 战斗克制优先于稀有度碾压

原作的乐趣来自持续反制：

- 声波需要耳机；
- TV 屏幕需要镜片或打断；
- Parasite 会被反寄生设备清除；
- 飞行与 Warp 绕过地面防线；
- Astro 护盾需要集中火力、缴械或 EMP；
- Titan 需要阶段破坏，而不是单一血条。

因此传说角色应更强，但不能让所有普通和稀有角色失去用途。低稀有角色可以通过快速升星、特定抗性和生产效率继续进入阵容。

### 首版角色池研究候选

以下仅是基于原作辨识度和玩法覆盖的研究建议，尚未替代 GDD 的待决定项：

| 角色 | 建议稀有度 | 车间 | 建议职责 |
|---|---|---|---|
| Normal Skibidi Toilet | 普通 | 普通 | 低成本近战 |
| Large Skibidi Toilet | 普通 | 重装 | 基础承伤 |
| Jetpack Skibidi Toilet | 稀有 | 飞行 | 后排突袭 |
| Dual Laser Strider | 稀有 | 飞行 | 机动远程 |
| Parasitic Skibidi Toilet | 稀有 | 特殊 | 短时控制或召唤感染体 |
| DJ Skibidi Toilet | 史诗 | 特殊 | 声波击退与团队增益 |
| Berserker Skibidi Mutant | 史诗 | 重装 | 冲锋、承伤、破甲 |
| G-Toilet 早期形态 | 传说 | 重装 / 特殊 | 领袖型攻城输出 |

该八人池覆盖六人编队、重复上阵、四类车间、四档稀有度、飞行、控制、辅助和 Boss 级成长。

## 禁止混入的非正史内容

除非 GDD 明确建立联动或平行宇宙章节，否则不得把以下内容作为原编号系列事实：

- DOM Studio 的 `Skibidi Toilet Multiverse`；
- Virlance、MonsterUP 等同人系列角色；
- Roblox 游戏原创单位和稀有度；
- 社区战力榜、同人升级形态和未发布泄漏；
- 只存在于模组、短视频二创或 AI 图片中的角色；
- `Emergence` 独有设定被无说明地塞入 Episode 1–79 主线。

同人内容可以作为玩法灵感，但数据必须标记 `continuity: fanon`，并与 `continuity: original-1-79` 分开。

## 当前未解之谜

这些问题在原作中尚未完全解释，不应由游戏擅自宣布唯一答案：

- Skibidi Toilets 的完整起源和 Alpha-Hills 的真实实验过程；
- Secret Agent / Administration 的最终目的；
- G-Toilet 背叛 Astro 的完整原因；
- Astro 帝国的最高统治者和全部等级；
- Titan Cameraman 在 Episode 74 后的最终状态；
- Watchman of Doom 能否被解除控制；
- 原编号 Episode 80 与 `Emergence` 的最终关系；
- Humans、硬件头族群与 Skibidi 转化之间的完整生物或机械机制。

首版应把这些悬念保留为背景，不用大量文本解释。

## 资料入口

### 总览与时间线

- [官方 Skibidi YouTube 频道](https://www.youtube.com/@skibidi)
- [Skibidi Toilet 系列总览](https://skibidi-toilet.fandom.com/wiki/Skibidi_Toilet_series)
- [Wikipedia 故事摘要](https://en.wikipedia.org/wiki/Skibidi_Toilet)
- [Alpha-Hills Siege](https://skibidi-toilet.fandom.com/wiki/The_Siege_of_Alpha-Hills)
- [Episode 57：解除 Titan Speakerman 感染](https://skibidi-toilet.fandom.com/wiki/Skibidi_toilet_57)
- [Episode 77：Astro 战争与 Watchman of Doom](https://skibidi-toilet.fandom.com/wiki/Skibidi_toilet_77)
- [Episode 79](https://skibidi-toilet.fandom.com/wiki/Skibidi_toilet_79)
- [Emergence 1](https://skibidi-toilet.fandom.com/wiki/Skibidi_toilet%3A_emergence_1)

### 阵营与角色

- [Factions](https://skibidi-toilet.fandom.com/wiki/Factions)
- [Skibidi Toilets 角色索引](https://skibidi-toilet.fandom.com/wiki/Category%3ASkibidi_Toilets)
- [The Alliance](https://skibidi-toilet.fandom.com/wiki/The_Alliance)
- [Astro Toilets](https://skibidi-toilet.fandom.com/wiki/Astro_Toilet)
- [G-Toilet](https://skibidi-toilet.fandom.com/wiki/G-Toilet)
- [Chief Scientist Skibidi Toilet](https://skibidi-toilet.fandom.com/wiki/Chief_Scientist_Skibidi_Toilet)
- [Skibidi Mutants](https://skibidi-toilet.fandom.com/wiki/Skibidi_Mutant)
- [Parasitic Skibidi Toilet](https://skibidi-toilet.fandom.com/wiki/Parasitic_Skibidi_Toilet)
- [Titan Cameraman](https://skibidi-toilet.fandom.com/wiki/Titan_Cameraman)
- [Titan Speakerman](https://skibidi-toilet.fandom.com/wiki/Titan_Speakerman)
- [Titan TV Man](https://skibidi-toilet.fandom.com/wiki/Titan_TV_Man)
- [Watchman of Doom](https://skibidi-toilet.fandom.com/wiki/Watchman_of_Doom)
- [Secret Agent / Administrator](https://skibidi-toilet.fandom.com/wiki/Secret_Agent)

## 验证

- 世界观总览与主冲突由官方发布序列和多来源故事摘要交叉验证；
- Episode 57、Alpha-Hills、Episode 77、Episode 79 分别用于核对治愈、地下设施、Astro 入侵和当前战局；
- 角色名称与能力优先采用角色页和 episode 页共同出现的内容；
- 推断、社区名称和游戏改编均已显式标记，不与原作明确事实混写；
- 每次引入新官方集数或 `Emergence` 内容时更新 `last_verified` 并重新检查阵营关系与角色状态。

## 相关节点

[KM:domain.product](../../domains/product.md)、[KM:reference.skibidi-toilet-idle-siege-gdd](skibidi-toilet-idle-siege-gdd.md)。
