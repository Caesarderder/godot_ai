# 幻想放置远征队同类游戏：访谈上下文

- Task statement: 调研 Steam《幻想放置远征队 / Duelist: Idle Expedition》，并围绕用 Godot 制作同类单机休闲放置游戏进行深度访谈。
- Desired outcome: 形成兼顾制作人、玩法策划与 Godot 技术落地的执行级产品规格，而不是立即编码。
- Stated solution: 联机搜索原作玩法、设计和公开可确认的技术信息；尽可能使用相关 Godot skills 与用户讨论。
- Probable intent hypothesis: 用户希望抓住近期热门的“桌面底边常驻 + 自动战斗 + JRPG 队伍构筑 + 刷宝营地循环”机会，同时做出可控规模、可实现且有自身差异化的产品。
- Known facts/evidence:
  - 目标游戏 Steam App 4282780，Demo App 4627050；开发 One Interactive Studio，发行 Infini Fun，正式版计划 2026 Q3。
  - 原作是任务栏/桌面底边常驻的像素 JRPG 自动战斗放置游戏；公开内容包含 7 主职业、21 子职业、91 细分职业、200+ 装备、60+ 职业专属传奇装备。
  - 核心双循环：前线自动战斗、刷关、掉落、成长；营地酒馆招募、铁匠锻造、商店资源转换与设施升级。
  - Demo 当前含多队同时战斗（最多 3 队）、Steam 云存档、Boss、敌人情报、快捷编队、自动锻造入库等。
  - 公开玩家观察：每关重复战斗积累追随者/进度后开启擂台决战；角色有天赋、潜力、技能和武器/防具/饰品三件装备；数值战力不完全等价于实战强度。
  - SteamDB 将 Demo 技术识别为 Unity Engine；未发现公开源码或完整程序架构说明。
- Constraints: 当前是 deep-interview 需求澄清阶段，不直接实现；目标引擎为 Godot；目标平台改为手机端（Android/iOS 待进一步确认），不是 Steam 桌面常驻产品。
- Unknowns/open questions: 用户真正想复制的核心吸引力、差异化主题、首版规模、目标用户、付费/售价、团队与资产能力、在线挂机还是离线结算、窗口形态、战斗可控深度、内容量与上线周期。
- Decision-boundary unknowns: 哪些系统可由代理按最佳实践自主决定，哪些产品/商业/美术方向必须逐项确认。
- Likely codebase touchpoints: 这是绿地游戏设计；当前仓库中的 project-a 是 Godot AI 插件样例，与目标游戏实现无直接产品继承关系。
- Prompt-safe initial-context summary status: not_needed

## Docs Hunter Pass

- Goal: 为同类 Godot 游戏设计建立事实与仓库路线。
- Knowledge map: 未发现与目标游戏对应的仓库知识地图；仅发现 project-a Godot 插件样例。
- Docs checked: AGENTS.md 指令、GodotPrompter docs-hunter、godot-brainstorming、godot-master 及放置/2D/Resource/Save/UI 专项。
- Route: 绿地产品访谈 -> 竞品事实 -> 产品边界 -> 核心循环/差异化 -> Godot 架构 -> 验收规格。
- Decision: BUILD_MINIMAL（先形成最小可验证产品规格，不继承无关插件代码）。
- Risk: 把 Demo 当成完整正式版、把公开表现误当内部源码、范围被 91 职业与 200+ 装备拖垮。
- Next action: 先确认用户要复刻的核心价值主张，再讨论范围和技术。

## Interview Round 1

- [from-user] 核心承诺选择“挂机刷宝爽感”，并希望采用经典 Meta 元素。
- [from-user] 平台明确为手机端，因此桌面底边陪伴不再是产品核心。
- Interpretation: 前台自动战斗提供持续掉落，玩家回流时通过开箱、鉴定、筛选、换装、强化与跨系统 Meta 成长形成爽点；具体主操作与 Meta 范围仍待澄清。

## Interview Round 2

- [from-user] 期望整体玩法循环具有开罗游戏的感觉。
- [from-user] 通过大任务与小任务形成层层目标，让玩家持续获得正反馈，并清晰看到自身提升。
- Interpretation: 任务不是附属成就列表，而可能是贯穿成长节奏的目标骨架；尚需明确它是强制推进门槛、主线引导器，还是可选奖励层。

## Interview Round 3

- [from-user] 任务采用自由引导，不设置强制限制或硬解锁门槛。
- [from-user] 未升级营地的玩家会因为自然战力不足而难以推进，任务只是把相关内容串联起来，促使玩家自发参与。
- Pressure-pass finding: 对“大任务/小任务形成目标感”的假设进行权力边界复核后，确认采用“任务强引导 + 系统软门槛”，拒绝“任务硬门槛”。
- Non-goal established: 不用必须完成指定任务才能开放后续内容的强制任务链。

## Interview Round 4

- [from-user] 首个可玩版本希望包含四套 Meta：英雄招募与培养、队伍编成、装备词条与强化、营地设施升级。
- Scope tension: 原问题要求最多三套，用户明确选择四套，说明四者共同构成不可缺失的产品闭环；需要确定其中哪一套首版只做薄层。

## Interview Round 5

- [from-user] 营地设施升级可以作为首版最薄的一套系统。
- [from-user] 主系统应调整为英雄培养；英雄与队伍编成是最重要的体验。
- Product hierarchy: 英雄培养与编队为主，装备词条与强化服务于英雄构筑和刷宝反馈，营地仅提供轻量产能、任务节点与长期节奏。

## Interview Round 6

- [from-user] 英雄采用开罗游戏式随机生成模式，不采用固定姓名、固定立绘和专属技能的手工英雄池。
- Implication: 英雄差异主要由职业、随机资质、天赋/性格、技能组合和培养经历形成；玩家收藏的是独特实例及其成长故事。
- Non-goal established: 首版不走重剧情、重立绘、固定角色抽卡池路线。

## Interview Round 7

- [from-user] 接受首版核心验收标准。
- Acceptance criterion: 新玩家前 30 分钟至少招募 8 名随机英雄；因职业或资质差异主动换人/调整编队至少 2 次；获得至少 1 件能明显改变战力或流派的稀有装备；依靠这些成长击败一次此前失败的关卡。
