---
km_id: reference.verification-matrix
km_type: reference
domain: quality
status: active
owner: verification
last_verified: 2026-07-27
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/constraints/first-30m-contract.md
  - docs/references/constraints/implementation-status.md
  - project-a/project.godot
  - project-a/tools/run_research_onboarding_tests.gd
  - project-a/tools/run_first_30m_journey_tests.gd
  - project-a/tools/run_battle_hud_screen_tests.gd
  - project-a/tools/run_legion_screen_tests.gd
  - project-a/tools/run_factory_screen_tests.gd
  - project-a/tools/run_research_breakthrough_tests.gd
  - project-a/tools/run_goals_screen_tests.gd
  - project-a/tools/run_campaign_objective_projection_tests.gd
validated_by:
  - manual-verification-plan-review-2026-07-26
  - python3 tools/docs_lint.py
  - godot --headless --path project-a -s tools/run_research_onboarding_tests.gd
  - godot --headless --path project-a -s tools/run_first_30m_journey_tests.gd
  - godot --headless --path project-a -s tools/run_battle_hud_screen_tests.gd
  - godot --headless --path project-a -s tools/run_legion_screen_tests.gd
  - godot --headless --path project-a -s tools/run_factory_screen_tests.gd
  - godot --headless --path project-a -s tools/run_campaign_objective_projection_tests.gd
  - godot --headless --path project-a -s tools/run_research_breakthrough_tests.gd
  - godot --headless --path project-a -s tools/run_goals_screen_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
tags:
  - reference:verification-matrix
  - quality:acceptance-gate
related:
  - reference.first-30m-contract
  - reference.toilet-factory-refactor-plan
  - runbook.game-verification
  - reference.game-state-measurement-framework
---

# 验证矩阵

## 证据原则

当前 v6 测试是可复用技术基线，不证明 v3 SLG 合同。新里程碑必须分别记录实现引用、focused
自动证据、浏览器证据和需要真人判断的体验证据。

| 里程碑 | 自动证据 | 交互/设备证据 | 真人证据 |
|---|---|---|---|
| M0 合同与迁移护栏 | 契约 validator、docs lint、v6 golden save | — | 范围复核 |
| M0.5 策划度量基线 | FM/TFA/FL 复算、来源消耗守恒、CP 候选敏感性、关卡需求扫描 | 状态仪表盘可读性 | 能否正确解释卡关与下一行动 |
| M1 永久角色内核 | 升级后属性与 `ΔCP`、三星、技能、派驻、六槽、存档 | debug/query inspection | 理解等级与星级差异 |
| M2 工厂永久成长 | 离线产出、容量、时间回拨、设施升级、成长成本守恒 | 工厂页 844×390 | 工厂产出能形成清晰成长选择 |
| M3 城镇无损纵切 | 胜败撤退、无损结算、reward manifest、exact-once、digest | 3D 战斗、HUD、结算 | 能理解失败成本与下一成长动作 |
| M4 UI/UX | view model、command routing、手动技能、复盘、阵位候选、UI smoke | 四屏、战区直接出击、战术 HUD、结算、编队 844×390 | 无指导完成核心操作 |
| M5 首 30 分钟 | deterministic flow、存档恢复、经济守恒 | 844×390、刷新/关闭、20m session | 复述双向循环并愿意再战 |
| M6 Web 候选 | 全套 headless、export、artifact audit | Android Chrome、iOS Safari、生产 HTTPS | 最终 scope audit |
| M7 长期进度 | v5/v6/v7→v8、周期 generation、批量领奖幂等、十抽 A、60 抽 S、专属数据升星、六槽替换、保底持久化 | 三页签、顶层待领取数、30 级奖励轨、招募结果与编队编辑 844×390 | 周期目标是否强化攻城而非红点劳动 |

## 2026-07-27 当前证据

- M1–M3：`run_balance_tests.gd`、`run_slg_loop_tests.gd`、`run_lifecycle_tests.gd`、
  `run_battle_tests.gd`、`run_campaign_tests.gd` 覆盖升级属性与 `ΔCP`、首章旅程、永久角色、三星、
  派驻、无损结算和 Boss；`run_factory_casualty_tests.gd` 补充无损结算、幂等与旧 schema 迁移兼容。
- M0.5：`run_first_chapter_balance_scan.gd` 使用 7 个新档种子扫描真实 `BattleSession`，
  验证同一 Gman 在前三关开局属性一致、前三关稳定胜利、1-4 单人必败及三人基础编队稳定反攻。
  1-3 已从原 82–102 秒两轮收紧至 51.6–69.2 秒，结束生命仍为 5.6%–32.8%；
  1-5 基础三人 7/7 全败，冲锋升星和装甲升星
  两条命名路线分别 7/7 全胜并落入 70–120 秒自动合同。扫描器会真实执行基础研究、领取和编队，
  不再把“研究开始事件”误当作已授予英雄。`run_first_30m_journey_tests.gd` 另以 14 个干净新档
  （7 seed × 冲锋/装甲二星）串起真实战斗、结算、研究所、十连、编队、资源设施投产与首批
  后勤收取、升星和存档恢复，全程没有直接改状态或注入货币，并使用真实默认
  `auto_skill=false`：普通战斗技能就绪即手动释放，Boss 最终阶段保留到 5 秒预警。两条路线均在
  524–598 秒模型时间内完成且账本非负；冲锋 7/7 至少压制一次巨炮，装甲 7/7 至少守住一次
  炮击。Boss 机制可读性和
  真人接受度仍待验证。
- 内容数据门禁：`run_stage_definition_tests.gd` 校验首章五个 typed `.tres` 的唯一稳定 ID、
  章节坐标、范围、必填威胁/反制文案，以及运行时推荐战力、敌方倍率、单人压力和 Boss 耐久投影；
  随后的 98 场扫描防止数据迁移静默改变首章胜负与时长合同。
- 应用/资产边界：`run_app_bootstrap_tests.gd` 验证显式服务注入、幂等启动和缺失服务失败；
  启动 smoke 与 lifecycle suite 验证真实 Autoload 顺序。`run_asset_3d_tests.gd` 验证八个
  game-owned wrapper scene 均含可渲染网格，`run_presentation_tests.gd` 验证其战斗投影；
  新 Web 包随后通过 artifact audit 与完整 Chrome/PWA smoke。
  `run_font_coverage_tests.gd` 扫描实际运行时脚本、场景、Resource 与项目配置，并通过导入后的
  `FontFile.has_char()` 阻断中文、ASCII 或界面符号漏字；tools、截图证据与零入口 legacy Shell
  不计入玩家字符集。
  `run_ui_focus_tests.gd` 逐一实例化七个 authored UI scene，验证静态按钮、动态 CTA、阵位、关卡
  与战斗技能覆盖层均为 `FOCUS_ALL`、可取得焦点且具有非空白高对比 focus style。
- M4：`run_ui_smoke_tests.gd` 已迁移到新四入口 App Shell；目标页刷新并呈现新合同里程碑；
  标题、设置、全局自动技能、主动暂停和失焦暂停已接入实际入口；第五章胜利进入独立尾声并可继续
  无尽前线；指挥情报页已展示当前编队 `CombatPower`、能力比、风险、紧缺资源和行动建议；
  战斗页已覆盖自动/手动技能模式、逐英雄技能按钮与阶段 HUD，结算覆盖真实战斗复盘和成长去向，
  军团页覆盖选中阵位后的首屏候选角色；review 回归另覆盖 snapshot 信号复用、减少动态下的
  工厂静态降级，以及战果保存失败的阻断式幂等重试入口；
  横屏壳层回归另覆盖 568×320 短屏、667×375 旧手机、844×390 基准、932×430 现代手机、
  1024×768 平板、1280×540 超宽和 390×844 方向门禁；自动断言 CSS 安全区探针、48 CSS 像素
  触控换算、旋转期间战斗安全暂停和页面恢复。设置页覆盖双栏独立滚动，工厂覆盖新档空地、
  可负担建造 CTA、原子落成和存档往返；
  战斗暂停回归覆盖全屏输入拦截、同一战斗会话冻结、继续、撤退、音量、减少动态、失焦保持暂停
  和语义返回键识别。
  `run_battle_hud_screen_tests.gd` 另对独立 `BattleHudScreen` 验证阶段/战线/炮击倒计时投影、
  编队对应的冲锋打断/装甲承炮提示、自动/手动技能状态、满能量 CTA、阵亡解释，以及 1-1
  首次技能的整卡点击提示与成功确认；Compatibility 844×390 截图和 Web Chrome smoke 均已
  覆盖集成后的真实战斗画面。`ui-first-skill-tutorial-844x390.png` 另记录提示位置、触控目标和
  战场留白；它不替代目标玩家首次理解盲测。
  `run_presentation_tests.gd` 进一步验证 accepted 装甲格挡事件在中画质产生文字、防御环、核心
  闪击、受控镜头震动与独立音效，在低画质/减少动态下保留文字和形状但移除次级闪击与震动；
  `ui-battle-guard-counter-844x390.png` 证明关键反馈位于基地轮廓上方且不遮挡技能卡。
  `run_legion_screen_tests.gd` 对独立 `LegionScreen` 验证下一关战力差、候选职责、换人后的军团
  战力变化和语义部署请求；新 844×390 军团截图显示首屏即可比较阵位，而旧动态军团树移除后
  UI smoke 与 Compatibility capture 均不再产生退出资源泄漏。
  `run_first_formation_flow_tests.gd` 进一步使用真实 App Shell 与命令执行器，验证十连后默认
  空前排、装甲/冲锋依次推荐、两次上阵持久化、下一空位推进和精确 1-4 反攻 CTA；
  `ui-first-formation-844x390.png` 证明首次候选与职责说明在基准横屏首屏内可见。
  `run_factory_screen_tests.gd` 对独立 `FactoryScreen` 验证固定库存、互斥 HUD、研究所资格解释、
  三步网格建造和“确认后才扣资源”的交易边界；新 844×390 截图证明库存文案不换行挤压，
  右侧建造决策与左侧 3D 选址同时可见。
  研究所回归覆盖 1-4 首败后的主动建造入口、带主干连线的四分支八节点科技蓝图、两个基础节点 CTA 和返回基地路径。
- 首败研究纵切：`run_research_onboarding_tests.gd` 覆盖早期失败不解锁、1-4 首败只授予建造资格、
  玩家主动放置并建成研究所后才开放冲锋与装甲蓝图、两者分别授予稳定 ID 永久角色、重复解锁拒绝、
  三人六槽上阵以及后续失败不重复触发。
  `run_research_breakthrough_tests.gd` 进一步覆盖研究所落成后的一次性免费十连：正好十张、
  冲锋与装甲确定性永久入列、长期招募 A 保底不变、二次领取拒绝、原 receipt 安全回放和
  save roundtrip。`run_blueprint_screen_tests.gd` 另覆盖十连结果专注态、援军职责说明、无关
  分支退场、减少动态降级和“立即编入反攻队”焦点；`ui-research-breakthrough-844x390.png`
  记录真实 Compatibility 画面中的两名关键援军、八份次级资源与单一反攻出口。目标页 UI
  smoke 覆盖“大目标—中目标—小目标—当前坎—过坎办法—唯一 CTA”。
  `run_goals_screen_tests.gd` 独立实例化 authored `GoalsScreen`，覆盖三层目标、大小卡点、恢复
  文案、精确关卡 CTA、三页签语义信号、30 级战令轨和指挥官长期进度。
  `run_battle_result_screen_tests.gd` 验证 1-4 反攻后“选择工业支援”成为唯一高优先 CTA，
  不再让“进攻下一城镇”绕过资源设施、收取后勤与自主升星；`ui-action-auto-settlement-844x390.png`
  提供 844×390 Compatibility 视觉证据。
  `run_battle_hud_screen_tests.gd` 验证反攻开场的装甲承伤/冲锋压制提示；
  `run_first_formation_flow_tests.gd` 与 `run_battle_result_screen_tests.gd` 验证结算从真实出战、
  逐角色伤害和承伤统计生成过坎证据；`ui-counterattack-proof-844x390.png` 证明 844×390 下
  因果复盘与下一行动同时可读。
  `run_first_growth_flow_tests.gd` 覆盖反攻结算 CTA 直接进入资源设施选择、非资源设施延后、
  建成后定位投产收取、收取后并列两条 Boss 成长路线、真实 CP/成本预览、两按钮可选以及
  `upgrade_hero_star` 命令后立即进入行动七；`ui-first-industrial-choice-844x390.png` 与
  `ui-first-growth-choice-844x390.png` 证明三个设施和两条成长路线分别在基准横屏首屏可操作。
  同一聚焦测试继续覆盖升星后所选路线、统一战力对比、5 秒技能时机和精确 1-5 战斗入口，并
  分别验证“成长未完成”“巨炮机制/技能时机”“阵容/战力”三类失败恢复；
  `ui-boss-ready-844x390.png` 与 `ui-boss-timing-recovery-844x390.png` 证明验证态和时机失败
  结算在 844×390 首屏只保留匹配的主要行动。
  `run_chapter_one_completion_tests.gd` 验证首章专属标题、冲锋压制与装甲格挡两种真实路线证明、
  七行动闭环、按当前状态生成的第 2 章/招募/战令解锁摘要，以及“侦察 2-1”只打开战前地图而
  不强制续战；`ui-chapter-one-complete-844x390.png` 证明奖励、贡献、路线兑现、实际解锁和
  下一章主 CTA 在基准横屏共同可读。
  `run_campaign_tests.gd` 与 `run_ui_smoke_tests.gd` 共同锁定首墙侦察口径：1-4 玩家可见
  反制只指向研究所免费十连、永久装甲/冲锋援军和反攻，不再泄漏旧图纸、九兵量产或三合一；
  1-5 推荐只保留两条已验证二星路线，首章巨炮预警合同为 5 秒；
  `ui-first-wall-reconnaissance-844x390.png` 提供真实战区首屏证据。
  `run_balance_tests.gd` 与 UI smoke 进一步验证情境行动优先级：1-4 零尝试时即使能力比极低，
  也只显示 48px“试探炮台防线”且隐藏通用培养按钮；记录一次尝试后才恢复成长建议。
  同一领域测试覆盖首败后“建研究所 → 免费十连 → 编队 → 反攻”的持久状态矩阵；UI smoke
  验证战区“建造研究所”语义行动准确打开研究设施而非通用军团页，
  `ui-first-wall-recovery-844x390.png` 保存首败恢复首屏。
  `run_chapter_one_completion_tests.gd` 继续覆盖章节间承接：2-1 极高风险侦察同时提供 48px
  “先培养军团”和“仍要试探”，安全行动不启动战斗而打开军团；七行动结束后的目标中心改为
  第二章大/中/小目标、真实挑战线缺口和非付费恢复说明。视觉证据为
  `ui-chapter-two-handoff-844x390.png` 与 `ui-chapter-two-goal-844x390.png`。
  同一测试还覆盖跨会话投影：标题摘要显示第二章真实缺口，“返回指挥室”后的基地任务替换已完成
  新手卡并继续以“先培养军团”进入军团，不回旧章节或自动开战；
  `ui-chapter-two-resume-title-844x390.png` 与 `ui-chapter-two-resume-base-844x390.png`
  保存 844×390 恢复态证据。
  `run_campaign_objective_projection_tests.gd` 在不经过 UI 的情况下锁定同一事实 owner：
  首章进行中保留当前小目标；首章完成但低于 2-1 挑战线时，标题/基地/目标中心共享精确战力缺口
  与“先培养军团”；达到挑战线后，三者共同切换为侦察 2-1。该测试防止 App Shell 的跨页面
  文案和路由重新分叉。
  网格建造回归覆盖用途卡、费用可读性、三步引导、空格选择、确认前不扣款、坐标持久化以及
  `ui-construction-placement-844x390.png` 放置态证据。
  帮助中心回归覆盖标题/设置双入口、双栏滚动、建造与技能说明、隐私与运行版本、48 像素返回
  操作，以及 `ui-help-844x390.png` 真实渲染证据。
  标题入口回归覆盖新档、进行中和五章完成三种主 CTA，并校验城镇、英雄、指挥等级、下一目标
  均来自当前持久状态；`ui-title-844x390.png` 提供旧档渲染证据。
  `capture_ui_review.gd` 已在本机 Compatibility 图形运行生成标题、设置、基地、指挥情报、战区、
  军团、目标、终章、战斗与结算的 844×390 截图。
- M6 本地部分：Web release export 与 `release_audit.py --artifact-dir build/web` 通过；
  原创 PWA/application 徽记通过 safe SVG 校验，并由同一 Web preset 导出 144/180/512 与
  Apple touch PNG；32 像素缩略检查仍能辨认瓷甲盾、工厂核心与突破箭头。
  `run_web_browser_smoke.mjs` 通过本机 HTTP 和真实 Chrome 验证 844×390 WebGL2 Canvas、390×844
  原生竖屏提示、1280×540 超宽横屏、旋转恢复和触控进入基地，
  PWA Service Worker 接管、在线刷新与关闭服务器后的离线重启；运行阶段无控制台/意外网络错误，
  `/userfs/.../save_v1.json` 在在线刷新及离线重启前后身份保持；设置页可下载合法 v8 JSON，再经
  浏览器文件选择器导回、预览、二次确认恢复，并将旧主档保留为 `.bak`。
  `run_web_first_battle_smoke.mjs` 另用隔离新 profile 从标题经基地真实进入 1-1，持续发出英雄卡
  触控并等待正常结算；当前 Chrome 150 于 844×390 在 53.7 秒完成，IndexedDB 主档记录
  `stage_1_1` 通关且尝试次数为 1，全程 0 运行时异常、0 非预期控制台错误、0 网络失败。
  `browser-first-battle-844x390.png` 与 `browser-first-battle-result-844x390.png` 分别保留
  战斗目标 HUD 和“城镇已占领”结算证据；重复触控本身不冒充真人主动技能理解证据。
  候选构建现对 HTML/JS/WASM/PCK 记录确定性 gzip-9 体积并执行 30 MiB 硬门禁；排除零引用的
  legacy `scripts/main.gd` 并加入正式品牌启动图后，revision `127323a` 的当前 PCK 为
  `18.92 MiB`，gzip-9 初始 payload 为 `27.62 MiB`，仍低于 30 MiB 硬门槛，但比 20 MiB
  目标高 `7.62 MiB`。新增两条 OGG 音乐约占 3.88 MiB 原始体积；16.06 MiB 的完整 Noto CJK
  源字体是下一项主因，不能用系统字体替代 Web 中文覆盖。运行字符清单当前为 981 个，
  `run_font_coverage_tests.gd` 必须在任何裁剪后重新证明全部覆盖。
- M8 本地试玩证据工具：`run_platform_tests.gd` 覆盖显式 opt-in、事件白名单/去重、256 条上限、
  版本/样本量/时间窗、续接、导出和关闭删除；同一报告从白名单事件派生 12 个首章里程碑、相邻
  节点耗时、下一缺失节点、首个有效输入、关卡尝试、失败命令、纯导航连跳和排除战斗区间后的
  最长停滞。越序升星不会绕过研究所、编队与后勤节点，并明确这些指标不能证明理解或乐趣。
  Chrome smoke 覆盖报告下载、隐私字段检查、在线/离线续接与 IndexedDB opt-out 删除。真实
  20–30 分钟样本与玩家访谈仍未发生。
- 首章战斗心流诊断：`run_platform_tests.gd` 锁定技能成功/过早点击、分关手动输入和最长手动
  战斗决策间隔，不携带英雄 ID；暂停及自动技能区间不会产生假 90 秒停滞。Settings/UI/Lifecycle
  回归锁定玩家可见状态与 App Shell 记录路径；这些指标只为 5 人盲测定位录像，不替代中立访谈。
- Web 私密存储证据：`run_web_private_storage_smoke.mjs` 通过 CDP 原生隔离上下文证明同一 Chrome
  私密会话刷新后存档 hash 不变，销毁上下文再新建时得到不同存档；设置页截图同时证明玩家看到
  “未确认持久存储”与下载备份指引。该证据不等于 IndexedDB 被完全禁用，也不替代生产源验证。
- M7 领域与 UI：`run_meta_progression_tests.gd`、`run_meta_tests.gd`、`run_ui_smoke_tests.gd`
  覆盖 v8 往返、v5/v6/v7 迁移、任务与批量等级/战令/成就领奖、30 项成就、十抽 A、60 抽 S、
  专属数据升星、招募英雄六槽替换和顶层待领取计数；
  `ui-pass-844x390.png`、`ui-achievements-844x390.png`、`ui-recruit-result-844x390.png`、
  `ui-formation-edit-844x390.png` 提供本机渲染证据。
- 可访问性本地基线：`run_ui_focus_tests.gd` 验证作者场景和动态按钮均可聚焦且有高对比焦点样式；
  `run_font_coverage_tests.gd` 扫描运行时中文字符覆盖；`run_presentation_tests.gd` 验证“减少动态”
  会即时清除镜头震动，并关闭单位呼吸摆动、受击缩放和技能前冲，同时保留血条、状态颜色、
  炮击文字倒计时、技能结果和胜负结算等静音可读反馈。屏幕阅读器语义仍须在真实浏览器/设备验证，
  自动测试不能替代该项。
- 音乐表现基线：`run_music_director_tests.gd` 锁定标题静音、基地/战斗/Boss 状态、任意连续或
  中断淡化后只有一个 Stream voice、后台暂停/恢复和清理；Platform/Settings 测试覆盖默认值、
  旧配置回退、持久化、归一化与语义 UI 事件，UI smoke 锁定 App Shell 的标题、基地和普通战斗
  路由。真实 Web 首次手势、循环接缝和移动端 Stream 仍是浏览器/设备门禁。
- 首战目标反馈：`run_battle_hud_screen_tests.gd` 验证 HUD 从当前阶段第一个存活结构投影
  “突破/摧毁 + 名称 + 耐久”，并在路障死亡后切换到城市；表现、UI 与 battle 回归证明它没有
  改变领域结果。`ui-first-skill-tutorial-844x390.png` 使用真实 1-1 单阶段配置证明目标前缀与
  技能教学、三个战斗操作按钮在基准横屏内共存。
- 结构突破反馈：`run_battle_tests.gd` 锁定摧毁事件的 ID/名称/lane/kind，
  `run_presentation_tests.gd` 锁定普通画质的世界文字+冲击环以及低画质/减少动态的纯文字预算；
  `ui-first-breakthrough-844x390.png` 证明首战“防线突破”与 HUD 下一城市目标同时可读。
- 目标卡点内容边界：`ObjectiveHurdleDefinition` 与七个首章 `.tres` 分离稳定 task ID、大小坎、
  失败原因和过坎办法；固定 preload Catalog 校验唯一性与完整性，并向
  `CampaignObjectiveProjection` 返回 detached view。`run_objective_hurdle_definition_tests.gd`
  覆盖七段引导一一对应、1-4 大坎与免费十连恢复、未知 ID fail-closed 和共享 Resource 不可被
  view 调用方篡改；投影、研究引导、UI smoke 与 14 条新档旅程回归通过。
- 行动任务内容边界：七个 `OnboardingTaskDefinition` 引用十个
  `OnboardingObjectiveDefinition`，固定 Catalog 校验稳定顺序、唯一 ID、自然行为条件、CTA 和
  完整奖励预算；`run_onboarding_definition_tests.gd` 锁定 1-4 首败到免费十连的大坎恢复、
  工业建造—收取—二星成长三个小目标、未知 ID fail-closed 与嵌套 detached view。研究引导、
  SLG、Meta、UI、启动和 14 条首 30 分钟新档旅程回归通过。
- 免费突破十连内容边界：`ResearchBreakthroughCardDefinition` 与十个 `.tres` 锁定两张 A 级
  冲锋/装甲和八张研究物资；Catalog 校验顺序、稀有度、字段、重复英雄转数据与聚合预算。
  `run_research_breakthrough_tests.gd` 验证研究所门禁、十卡、英雄/蓝图永久性、资源 delta、
  pity 隔离、重复业务拒绝、receipt replay、存档往返及已有英雄转数据；`run_blueprint_screen_tests.gd`
  与 `run_first_formation_flow_tests.gd` 验证结果专注态、唯一编队 CTA、装甲/冲锋两次真实上阵和
  完成后直达 1-4 反攻。14 条新档旅程证明两条后续二星路线经济结果未漂移。
- 仍缺：Firefox 桌面、Android Chrome、iOS Safari、生产 HTTPS、真人首 20–30 分钟及最终 IP/商店审查。

## 必测不变量

- 永久角色不会删除；
- 实时 HP 不写回永久角色状态；
- 战斗结算 exact-once；
- 工厂最低产能和下一永久成长可达；
- 同资源不形成稳定自我增殖；
- 旧战备字段读取后归一为 100；
- v6 迁移失败可回滚；
- UI 不直接改持久状态；
- 无自动推图、量产单位或 P0 图纸抽取入口。
- UI、成长预览和关卡能力比只使用 `CombatPower`；不得使用账号总战力或页面私有公式；
- 角色等级升级必须同时增加基础属性与 `CombatPower`；
- 预制阵容通关不得替代从新档开始的经济可达性扫描；
- 金币不得显示为工厂直接生产；资源换算不得把独立门禁压成一个固定全局汇率；
- 新乘区、货币或商品必须通过通胀、死锁、内容寿命和非付费可达性审查。

## 现有可复用基线

- `run_battle_tests.gd`：确定性 tick、三段攻城与结果结构；
- `run_lifecycle_tests.gd`：命令、存档与重放；
- `run_campaign_tests.gd`：25 关内容骨架；
- `run_platform_tests.gd`：Web 生命周期；
- `run_presentation_tests.gd`：3D 事件投影；
- release export 与 artifact audit。

`run_factory_casualty_tests.gd` 已停止执行永久伤亡旧断言，现可作为无损结算和迁移兼容的补充证据；
它不覆盖首 30 分钟生产闭环或真人体验。

## 验证

使用 [CMD:game-verification](../../runbooks/game-verification.md#game-verification)；
自动测试、浏览器设备和真人试玩必须分别记录，不能互相替代。
