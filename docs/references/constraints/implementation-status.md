---
km_id: reference.implementation-status
km_type: reference
domain: code
status: active
owner: maintainers
last_verified: 2026-07-27
source_of_truth:
  - project-a/project.godot
  - project-a/scripts/slg_main.gd
  - project-a/game/scripts/state/game_state.gd
  - project-a/game/scripts/state/factory_state.gd
  - project-a/game/scripts/state/hero_state.gd
  - project-a/game/scripts/domain/factory/factory_service.gd
  - project-a/tools/run_research_onboarding_tests.gd
  - project-a/game/scripts/domain/battle/battle_session.gd
  - project-a/game/scripts/commands/command_executor.gd
  - project-a/game/scripts/presentation/audio_director.gd
  - project-a/assets/audio/asset_manifest.md
validated_by:
  - godot --headless --path project-a --editor --quit
  - godot --headless --path project-a --script res://tools/run_slg_loop_tests.gd
  - godot --headless --path project-a -s tools/run_research_onboarding_tests.gd
  - godot --headless --path project-a -s tools/run_ui_smoke_tests.gd
tags:
  - reference:implementation-status
  - risk:contract-drift
related:
  - reference.file-ownership
  - quality.stale-docs
  - reference.toilet-factory-refactor-plan
---

# 实现状态基线

## 当前代码事实

- 当前开发根是 `project-a/`，Godot 4.6.3、GDScript、3D、Compatibility、Web-first、手机横屏。
- 当前存档结构为 schema v8，新增长期进度状态、指挥官等级领取账本并继续迁移 schema v5/v6/v7；新存档内容合同为
  `toilet-factory-slg-v2`。
- 玩家入口已切换至独立 `slg_main.gd` App Shell；旧概率抽图、量产单位、一次性库存和补位页面
  均不可从新入口到达。研究所现有独立科技蓝图入口，通过耐久研发倒计时确定性解锁永久角色。
- 实际入口现从标题页开始；标题页和各主功能页可进入本机设置，支持主音量、三档特效、减少动态、
  全局自动技能、存储状态提示、JSON 备份下载、严格校验与二次确认恢复，以及双确认删除本地存档。
  导入限制为 2 MiB，不兼容或损坏备份不会覆盖当前进度；成功恢复时保留旧主档为 `.bak`。
  战斗提供显式暂停/继续，浏览器失焦或不可见时自动暂停，
  恢复焦点后必须由玩家主动继续。
- 新局仅拥有并编入 Gman；其他永久角色不再随新档赠送，可在后续战役 Boss 与招募进度中解锁。
  战役与招募共享 `GameState.allocate_hero_index()` 的单调分配权威，交错解锁保持稳定 hero ID 唯一。
  工厂以可点击的 3D 网格呈现六类建筑，三座资源建筑独立累计并点击收取陶瓷、零件和污水能源；
  城镇胜利产出金币、角色经验和工业技术。
- 战斗结算保留本局伤害复盘，但永久角色在结算后恢复为 100% 可出征，不创建维修订单。
- 1-4 首次战斗失败通过同一 `settle_battle` 事务幂等开放研究所建造资格；结算页主 CTA 直接
  前往研究所。建筑建造、设施升级与基础角色研发均先创建带绝对结束时间的耐久订单，到点验收/
  领取后才提交建筑等级或永久角色；基础节点免费且每种只授予一次。后续首章反攻节奏仍需真人首局验证。
- UI 已完成第一轮视觉层级刷新：战区采用城镇节点与单关详情，军团页首屏优先展示六槽编队，
  工厂使用资源容量条、升级收益预览、屏幕空间建筑标记和精确收取反馈。
- 战斗页已将原有领域技能请求接成玩家可见的自动/手动模式：手动模式逐角色展示能量并允许选择
  释放时机，战术条同时显示阶段、战线与炮击倒计时；暂停和撤退仍是独立操作。该改动不改变
  `BattleSession` 的 5Hz 确定性结算。
- 战后页新增基于真实 runtime result 的用时、击破、消灭、巨炮压制/命中复盘，并把战果映射到
  升级、扩建、研究或升星等下一步；军团选中阵位后在首屏直接出现候选英雄，不再依赖滚动到长卡片。
- 工厂点击建筑后优先展示该设施详情，资源设施、维修中心和研究所增加克制的运转动效；这些动效
  只属于表现层，不参与产出结算，并在“减少动态”开启时保持静态。
- 2026-07-26 review 已移除战斗 HUD 的额外 0.15 秒轮询，改为复用 `BattleWorld` 每个确定性 tick
  已生成的 snapshot 信号；战果持久化失败时进入不可绕过的重试页，以同一 battle_id 幂等重试，
  不再把空结算误显示为战败。
- 基地新增统一“指挥情报”：按当前编队的唯一 `CombatPower` 计算目标关能力比和风险区间，
  同时展示最紧缺后勤与可执行下一行动；旧战备与维修字段不参与当前建议。
- 首章前三关与 1-4 已使用当前编队的 `CombatPower` 口径：1950/2000/2020/5700。
  2026-07-27 扩展扫描证明前三关由唯一 Gman 获胜、1-4 单人必败，并在冲锋与装甲
  两名蓝图角色全部上阵后稳定胜利；三人编队 CP 为 5613–5860，与 5700 推荐线一致。
  当前 1-5 页面显示 6500；最新 7-seed 扫描中基础三人全败，冲锋升星与装甲升星两条
  命名路线分别全胜并落入 70–120 秒合同，因此该值恢复为自动校准候选。完整经济账本、
  Boss 机制可读性和真人选择质量仍未达到发布证据。
- 首章五关的稳定 ID、显示名、推荐战力、敌方倍率、单人压力、Boss 有效耐久、威胁与反制文案
  已迁移到 typed `StageDefinition` `.tres`；固定 preload catalog 会校验重复 ID、章节坐标、
  正数范围和必填文案。敌人阵型、结构模板和确定性战斗规则仍由 `StageCatalog`/`BattleSession`
  拥有，未把可变运行态写入共享 Resource。`run_stage_definition_tests.gd` 与 98 场扫描证明
  当前首章内容接入真实运行路径且数值结果保持一致。
- 确定性 `BattleSession`、`BattleWorld`、命令事务与主备存档作为基础设施继续复用。
- Autoload 启动已改为显式 `SaveManager → AppBootstrap ← Game` 组合：`Game._ready()` 不再查找
  sibling，最后注册的 `AppBootstrap` 注入保存服务并幂等触发加载/新建。八个外部角色 GLB 也已
  改由 `game/scenes/actors/ally_models` 的项目自有 wrapper scene 进入 `ToiletUnitView`；
  当前 App Shell 通过 Game 的窄接口执行备份/恢复/重置，不再直接查找 SaveManager；运行时代码
  没有 `res://artifacts` 依赖。启动、生命周期、3D 资产和表现测试均覆盖这些边界。包含新场景、
  typed Resource 和 wrapper 的单线程 Web 导出及本地产物审计已通过；真实 Chrome smoke 也已
  重新通过触控、方向切换、存档备份/导入/`.bak`、试玩报告 opt-in/opt-out、刷新及离线 PWA 重启。
- Web 导出物已通过本机 HTTP + Google Chrome CDP smoke：WebGL2 画布以 844×390 启动，可从标题进入
  基地，真实触控输入有效，PWA Service Worker 正常接管；在线刷新及关闭 HTTP 服务后的离线 PWA
  重启均成功，运行阶段无控制台或意外网络错误，Godot `/userfs` 中的 `save_v1.json` 始终保持同一
  身份；同一 smoke 还真实下载 v8 JSON、经浏览器文件选择器回传、显示预览、二次确认恢复并生成
  `.bak`；证据由 `tools/run_web_browser_smoke.mjs` 和六张 browser 截图生成。
- 设置页新增默认关闭的本地试玩报告：只记录白名单页面、命令结果、战斗结果和相对时间，最多
  256 条，不包含自由文本、payload、存档/账号/设备 ID 或网络地址；报告可下载、跨刷新与离线续接，
  关闭或清空时删除主档与 `.bak`。浏览器 smoke 已验证下载 JSON 的版本、样本量、时间窗和隐私字段，
  以及 opt-out 后 IndexedDB 删除；这只建立测量工具，不代表已经取得真人样本。
- 横屏 UI 壳层已按 844×390 重新收敛：页头使用稳定高对比承载层，底部四入口等宽分配，工厂详情
  改为按钮切换的单面板区域，通知改为不改变布局的浮层。Web 运行时以浏览器真实 CSS 视口而不是 Canvas
  backing size 判断方向；竖屏显示原生可访问旋转提示并拦截输入，战斗同时安全暂停，转回横屏保留
  当前页面且不自动解除暂停。Chrome smoke 已覆盖 390×844 竖屏、1280×540 超宽屏和 844×390
  恢复链路；Android/iOS 真机旋转仍待设备验证。
- 设置页已从单列长表单重构为横屏双栏：“体验设置”和“本地数据”各自独立滚动，存档危险操作
  不再与音画偏好混排。工厂已接入 5×5 网格建造：新档仅有指挥中心，玩家先选择建筑类型，再在
  3D 网格选址并二次确认；`construct_facility` 同时校验余额、边界和格子占用，随后原子扣款、
  持久化坐标并落成 Lv.1，资源设施从落成时间开始累计。旧存档已有设施会迁移到兼容的默认网格
  坐标，合法空地也可通过 v8 备份导入。工厂相机采用手机优先手势：单指滑动环绕旋转、单指轻点
  建筑或格子、双指捏合缩放；水平滑动控制方位角，垂直滑动控制受限俯仰角。滑动或捏合结束后不会
  误触建筑/格子，相机角度与缩放在进入建造、选择格子及界面刷新后保持不变；鼠标拖动和滚轮仅作为
  桌面调试兼容。
- 手机适配已集中到 `MobileViewportAdapter`：Web 端使用 `visualViewport` 处理浏览器地址栏造成的
  动态可视高度，并通过 CSS `env(safe-area-inset-*)` 探针把刘海/圆角安全区换算为 Godot 逻辑边距；
  原生端则把物理安全区按画布比例换算。适配器统一区分短横屏、标准横屏、超宽横屏、4:3 平板与
  竖屏门禁，并根据真实 CSS 缩放反算主要交互控件高度，使其不低于 48 CSS 像素。壳层只原位更新
  安全边距和方向遮罩，不在旋转时重建战斗状态。
- 战斗暂停已升级为全屏阻断式菜单：暂停时冻结战线和技能计时，保留同一 `BattleWorld` 会话，
  可继续战斗、主动撤退结算，并原位调整主音量和减少动态；失焦、屏幕按钮、Escape/Android
  返回键共享同一暂停入口，恢复焦点不会自动继续。
- 战后完全无损已在运行时、GC-004、生命周期测试和兼容回归中统一：失败、撤退与阵亡表现都不会
  降低永久角色战备、删除角色或创建维修订单。`run_factory_casualty_tests.gd` 已收口为当前无损
  合同与旧 schema 迁移检查，不再执行持久伤损、抽图或废料恢复等旧玩法断言。
- 当前工厂实现已从固定空地推进为 3D 网格放置：玩家先在紧凑按钮目录中比较设施与金币费用，再在
  左侧亮起的地格选择坐标，确认后才通过 durable command 扣款并持久化位置。移动 UI 明确展示
  “选建筑—点地图格子—确认”三步，放置前与放置中均已有 844×390 截图证据。该自由放置能力
  超出了 GC-003 仍描述的固定地块范围，暂不继续扩展道路、工人或复杂物流，等待范围统一。
- 标题页与设置页新增可返回原入口的横屏帮助中心，以双栏独立滚动说明核心循环、网格建造、
  自动/手动技能、暂停/撤退、手机方向、本地存档、隐私、版本、引擎、字体许可和非官方创作边界；
  844×390 下不依赖精确鼠标操作，返回按钮保持 48 基准像素。
- 标题页已从静态封面改为存档感知入口：新档显示“开始战役”，进行中显示“继续战役”，五章完成
  后显示“进入无尽前线”；同屏读取并展示 25 城占领数、永久英雄数、指挥官等级和下一目标，
  不在标题页提供误触重置或直接写存档的操作。
- UI 已完成第二轮玩家化重构：标题页改为灰镜战线无线电叙事入口，基地首屏以“前线来电”承载
  当前行动，建造、设施与行动改为按钮切换；战区首层使用城镇状态、威胁等级和直接出击，不再常驻推荐
  战力、战后实现规则与战术教程；军团首层直接呈现出击阵型。顶栏移除常驻指挥等级，设置收敛为
  单一菜单按钮，底部入口改为“工厂 / 战区 / 军团 / 行动”。工厂世界同步切换为低照度焦黑金属
  与暖色警戒光。该轮已通过 UI smoke 与 844×390 Compatibility 截图复核，真人沉浸感仍待验证。
- 长内容页面已统一滚动恢复契约：领取、升级、招募、阵位选择或页面刷新导致 App Shell 重建时，
  具名 `ScrollContainer` 会恢复各自的横纵位置。军团改为顶部“出击阵型 / 信号招募 / 成员培养”
  单选切换，科技蓝图改为四分支单选切换且不再使用整页滚动；工厂、设置保存/返回、行动页
  指挥官进度与分类切换保持固定，工厂不再使用滚动区。战令奖励由五列收敛为三列，避免
  844×390 横向溢出。设置和帮助的双栏长内容继续各自独立滚动。
- Web export 继续使用 `all_resources` 保护数据驱动依赖，但已按已验证的零引用边界排除旧
  `scripts/main.gd` App Shell；它保留在源码供迁移追溯，不再占用玩家首包。
- 工厂右侧 HUD 已进一步改为“行动 / 设施 / 建造”互斥按钮组，每次只投影一个系统面板，不再使用
  工厂详情 `ScrollContainer`。点击 3D 建筑会直接切到对应设施面板；建造目录收敛为两列紧凑按钮，
  选择后继续在左侧网格完成选址与确认。该 HUD 已由独立 `FactoryScreen.tscn + .gd` 接管，
  App Shell 仅持有 3D 世界、镜头/射线、网格选址和命令路由；研究所未解锁时直接显示 1-4 首败
  前置，放置页明确“确认后才扣资源”。
- App Shell 已明确采用 Godot `Control` anchors、`MarginContainer`、`Container` size flags 组成的
  Widget 式布局契约：全屏根、安全区、页头、内容区和底部导航随父矩形拉伸。浏览器 surface 在
  compact/standard/tablet/ultrawide 档位间变化时，非战斗页面会按原状态重建；568×320 短横屏会
  压缩工厂库存信息和右侧 HUD 宽度，恢复 844×390 后重新展示完整信息。UI smoke 会注入两种真实
  viewport snapshot，并断言 Shell、页头、库存、工厂面板和导航均未越出可见画布。
- 音频反馈已从运行时逐采样合成切换为 6 个已导入 OGG：统一按钮、建造成功/失败、战斗命中/技能/
  重击以及胜利、撤退、失败结算均有明确提示。素材选自 Kenney 的 UI Audio、Impact Sounds 和
  Music Jingles 官方 CC0 包，原始许可、来源 URL、选用文件和 SHA-256 记录在
  `assets/audio/asset_manifest.md`。音效池固定为 8 路并对同类高频事件做 45ms 防抖；首个按钮
  手势触发点击音以满足 Web 自动播放门禁。当前没有常驻背景音乐，不把短战果曲误写为 BGM。

## 新合同状态

2026-07-26 用户接受 v3 方向：

- 永久角色、等级、经验、星级、技能、被动与工厂专长；
- 工厂设施生产三种工业资源，不生产马桶人，不自动推图；
- 主动攻占城镇获得金币、经验、工业技术与突破资源；
- 战斗内伤害只决定本局结果，结算后永久角色完全恢复且不产生维修负担；
- 首个切片从 Gman 单人开局，后续永久角色随战役与招募进度解锁，并覆盖三星、六设施、三资源、
  四城镇和一个 Boss。

当前纵向切片已实现“收资源—选择投资—攻城—扩厂—二星派驻—继续推进—Boss”的旧七行动骨架，
并以 `run_slg_loop_tests.gd` 验证事务与无损结算。五章 25 关、章节导航、中段碎片、Boss 突破
奖励与无尽入口均可达；第二、三章 Boss 分别永久解锁自爆与双锯角色，其他角色由后续招募进度
补充。第五章 Boss 胜利进入独立终章尾声，汇总 25 城战果并提供里程碑与无尽前线续战入口。
新 App Shell 已补齐标题页、设置页与“目标”第四入口，呈现当前行动、25 城进度和新合同永久里程碑。
三星机制、主动技能三级研究、资源容量系统、统一战情仪表盘和 3D 建筑点击/独立收取已实现；研究所等级约束技能
研究，库存上限、升级扩容、溢出结算和存满时间均可见。14 条真实命令新档旅程已证明两条首章
成长路线经济可达、账本非负并可恢复存档；Android Chrome、iOS Safari 和真人
844×390 首 30 分钟体验仍待验证，
因此不能宣称完整商业产品完成。

## 可复用与必须替换

### 可复用

- 命令事务、revision、fingerprint、receipt、主备存档；
- `BattleSession` 确定性内核与 `BattleWorld` 表现分离；
- 25 关内容骨架、三段攻城和章节机制；
- 3D 角色/城市资产、Web Compatibility、设置与失焦暂停；
- 任务/成就的幂等领奖结构。
- 旧战功 30 级、抽取保底计数与 durable receipt 的技术形状。

### 必须替换

- 库存单位和永久删除权威；
- 单位生产队列、图纸研发和保底 P0 入口；
- 型号科技作为唯一成长；
- 一键补位、废料恢复和消耗式编队；
- 围绕上述规则的 App Shell 和测试断言。
- 旧任务中的单位生产/型号科技指标、旧成就中的库存单位指标，以及图纸材料混合抽取。

## 长期进度实现

行动任务、指挥官 30 级曲线、28 天 30 级免费战令、30 项永久成就和永久英雄信号招募已接入
当前 SLG App Shell。目标页以“行动 / 战令 / 成就”三个页签呈现；行动首屏进一步固定显示
“大目标—中目标—小目标—当前坎—过坎办法—唯一 CTA”，并按关卡与等级双条件渐进开放；
该目标中心已由独立 `GoalsScreen.tscn + goals_screen.gd` 接管，App Shell 只构建只读 view、
连接语义信号并路由幂等奖励命令，不再动态创建目标页控件。
Lv10 前隐藏周任务。军团页呈现概率、十抽 A、60 抽 S、定向保证、招募券和重复英雄数据；新英雄
可直接部署到六个阵位，已上阵英雄采用互换语义，重复英雄的专属数据优先支付升星需求，不足部分
才回退到通用英雄数据。顶层“目标”入口聚合显示等级、任务、战令与成就待领奖励数，成就支持
批量领取。研究所落成后另有一次免费研究突破十连，固定授予冲锋与装甲两名永久援军和八张
受控资源卡；该奖励不消耗券、不推进长期保底，并由 durable receipt 与存档 claim key 防重。
正式招募仍同时检查首章 1-5 完成与 Lv4，避免确定性教学闭环前出现随机全池入口。schema v8 保存周期 generation、领取状态、等级领取账本和招募双保底，并可
从 v5/v6/v7 原地迁移。旧 `QuestService`、`AchievementService`、`WarMeritTrack` 和
`BlueprintDrawService` 仍作为兼容代码存在，但不再是新 UI 的长期进度权威。

当前证据包含全套 headless 领域测试、UI smoke，以及行动、战令、成就、招募结果与编队编辑的
844×390 实机渲染；
时间加速测试已覆盖跨日、跨周、旧 generation 拒领、28 天赛季结转、免费轨未领奖励自动补发，
以及招募保底跨赛季保留。设备浏览器、真实 28 天行为和长期数值仍待真人验证，不能宣称赛季留存
或奖励比例已平衡。

## 实现声明规则

- focused test 通过前不得把任何新合同项写成 implemented；
- App Shell 接通前不得声称玩家可玩；
- 自动测试不能代替 844×390 浏览器与真人首 30 分钟；
- 新 schema 迁移通过前不得删除 v6 golden save 和备份；
- 商业 IP、真实支付和公开部署仍是独立外部门禁。

## 入口

[KM:reference.toilet-factory-refactor-plan](../plans/toilet-factory-refactor-plan.md)、
[KM:reference.toilet-factory-technical-design](../architecture/toilet-factory-technical-design.md)、
[KM:reference.verification-matrix](../indexes/verification-matrix.md)。
