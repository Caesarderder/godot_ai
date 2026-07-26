---
km_id: reference.toilet-factory-refactor-plan
km_type: reference
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-27
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/architecture/toilet-factory-technical-design.md
  - docs/references/constraints/implementation-status.md
  - docs/references/indexes/verification-matrix.md
validated_by:
  - node .codex/skills/godot-producer/references/practices/game-project-contract/scripts/validate-contract.mjs .
  - python3 tools/docs_lint.py
  - godot --headless --path project-a -s tools/run_first_30m_journey_tests.gd
  - python3 project-a/tools/build_web_candidate.py
tags:
  - workflow:implementation-plan
  - risk:major-migration
related:
  - reference.toilet-factory-technical-design
  - reference.verification-matrix
  - reference.first-30m-contract
---

# 永久军团 SLG 重构与上线计划

执行状态：`LOCAL VERTICAL SLICE IMPLEMENTED / EXTERNAL RELEASE GATES OPEN`。

本计划只描述当前仍有效的永久角色、后勤资源、研究突破、主动攻城和无损结算合同。量产单位、
图纸抽取、永久阵亡、跨局战备损失、维修订单和一键补位属于已取消旧方向；schema v8 中残留字段
只用于 v5/v6/v7 迁移，不得作为待实现功能。

## 交付原则

1. 玩家感受优先：每一刀必须改善理解、选择、张力、反馈或继续游玩的欲望。
2. 领域先于表现：价值操作通过 `CommandExecutor` 的 candidate-save-commit，UI 不直接写状态。
3. Godot 原生所有权：独立屏幕使用 `.tscn + typed .gd`；高频只读配置使用 typed `Resource + .tres`；
   运行态使用 `RefCounted`；Autoload 只保留真正的应用生命周期服务。
4. 渐进迁移：每次提取一个玩家可见 owner，不一次性重写 3,000 行 App Shell。
5. 证据分层：headless 证明规则，浏览器证明集成，真机证明兼容，真人证明好玩；四者不能互相冒充。

## 已完成：阶段 0—合同与迁移护栏

- `docs/game-contract.md` v7、主 GDD、产品边界和首 30 分钟合同已统一；
- schema v8 与 content `toilet-factory-slg-v2` 成为运行时权威；
- v5/v6/v7 迁移、主备恢复、损坏回滚、2 MiB 导入上限和严格预览已验证；
- 旧量产、图纸、维修和永久阵亡入口已从玩家路径移除；
- 项目契约 validator 与知识地图 lint 通过。

退出证据：`run_lifecycle_tests.gd`、`run_meta_tests.gd`、contract validator、docs lint。

## 已完成：阶段 1—永久角色与经济内核

- 新档只有稳定 ID 的 Gman，永久 roster、等级、星级、技能和专长成为权威；
- 六槽 `2×3` 编队只引用永久 `hero_id`；
- 金币、工业技术、芯片、突破数据和三工业资源分层；
- 所有成长同时更新真实属性和统一 `CombatPower`；
- 失败、撤退和阵亡表现不删除或伤害永久角色。

退出证据：`run_balance_tests.gd`、`run_slg_loop_tests.gd`、`run_factory_casualty_tests.gd`。

## 已完成：阶段 2—工厂后勤与研究突破

- 三资源设施独立产速、容量、离线锚和 exact-once 领取；
- 六座设施具备 locked/eligible/built、等级与 5×5 有界放置；
- 选择建筑、选择空格、二次确认后才原子扣款；
- 1-4 首败只授予研究所资格，玩家主动建成后开放一次免费突破十连；
- 十连固定含冲锋与装甲永久援军，不消耗招募券、不推进长期保底且不可重复。

退出证据：`run_grid_construction_tests.gd`、`run_research_onboarding_tests.gd`、
`run_research_breakthrough_tests.gd`、`run_factory_screen_tests.gd`。

## 已完成：阶段 3—首章战斗、目标与卡点

- 1-1 至 1-3 单人建立信心，1-4 单人稳定失败、三人稳定反攻；
- 1-5 基础三人稳定失败，冲锋二星和装甲二星形成两条可达解；
- 大/中/小目标、大小卡点、恢复办法与唯一当前 CTA 已进入行动页；
- 失败结算解释机制、战力或技能时机，不用付费捷径掩盖问题；
- 14 条干净新档旅程使用真实战斗、奖励、建造、研究、编队、成长和存档完成闭环。

退出证据：`run_first_chapter_balance_scan.gd`、`run_first_30m_journey_tests.gd`、
`run_goals_screen_tests.gd`、`run_battle_hud_screen_tests.gd`。

## 已完成：阶段 4—Godot 场景与内容架构

- Autoload 固定为 `SaveManager → Game → AppBootstrap`；
- `WarZoneScreen`、`BattleHudScreen`、`BattleResultScreen`、`LegionScreen`、
  `FactoryScreen`、`GoalsScreen`、`TitleScreen`、`SettingsScreen`、`HelpScreen`、
  `IntelligenceScreen`、`BlueprintScreen`、`EpilogueScreen` 和 `StageDetailPanel`
  已拆成 authored scene；
- 场景只投影 view model 并发出语义信号，App Shell 只负责 sibling wiring、路由和命令；
- 首章五关使用 typed `StageDefinition .tres`，固定 preload、稳定 ID 和启动校验；
- 八个角色 GLB 通过 game-owned wrapper scene 使用，不依赖导入器内部节点名。

玩家旅程中的高价值 screen 已完成提取。后续只在新界面具备独立生命周期、预览或测试价值时
新增 owner，不以“文件越多越架构化”为目标。

退出证据：各 screen focused test、`run_app_bootstrap_tests.gd`、`run_stage_definition_tests.gd`、
`run_asset_3d_tests.gd` 和 UI smoke。

## 已完成：阶段 5—本地 Web 候选

- Godot 4.6.3 Compatibility、单线程 Web/PWA、横屏、安全区和 48 CSS 像素触控目标；
- 双重独立导出完全一致后才晋级候选，manifest 绑定 clean revision 和每个 payload hash；
- artifact audit 拒绝源码 sidecar、线程运行时和超过 30 MiB 的压缩首载；
- Chrome 覆盖触控、七种视口、旋转门禁、备份导入导出、试玩报告、刷新、IndexedDB 与离线 PWA；
- 减少动态关闭镜头震动和装饰性单位动画；字体与焦点覆盖有自动门禁；
- 存档写失败不交换 live state，UI 明确“操作未生效”并引导下载备份。

当前压缩首载约 24.84 MiB，满足 30 MiB 硬门禁但未达到 20 MiB 目标。仓库已建立与 Godot
覆盖测试一致的 968 字符确定性清单；正式裁剪完整 Noto CJK 字体仍需获准安装官方 `fonttools`。

## 进行中：阶段 6—玩家体验验证

必须由至少 5 名未接触项目的目标玩家完成 20–30 分钟盲测：

- 4/5 无口头提示完成核心闭环；
- 4/5 能解释 1-4 失败以及永久援军为何有效；
- 4/5 能比较冲锋/装甲两条成长路线；
- 3/5 主动表达继续游玩意愿；
- 任一段连续 90 秒没有新判断、有效操作、清晰反馈或期待兑现即记录为节奏缺陷。

使用默认关闭的本地试玩报告记录白名单事件和相对时间；报告派生 8 个首章里程碑、关卡尝试、
失败命令、纯导航连跳和排除战斗后的最长停滞，不得记录账号、设备、网络地址、自由文本或完整存档。
这些指标只帮助观察者定位复盘片段，不能代替中立访谈。自动旅程的模型时间不能冒充真人
20–30 分钟体验。

## 待完成：阶段 7—生产发布

- Firefox 桌面、Android Chrome、iOS Safari 真机；
- 最低目标手机的冷启动、30 FPS、峰值内存与 30 分钟稳定性；
- 最终 HTTPS URL、WASM MIME、压缩、缓存、安全头和生产源存档身份；
- 私密/禁用存储降级、PWA 更新、回滚 artifact、触发条件和演练；
- 完整素材来源、字体 OFL、同人/IP、商店文案、隐私、支付与目标地区法律审查；
- Builda-controlled runtime/template 身份或经批准的替代发布路径；
- GitHub 凭据配置后推送冻结候选。

任何一项缺失时，只能称为本地候选，不能宣称“完全可上线”。

## 当前风险与控制

| 风险 | 控制 |
|---|---|
| `slg_main.gd` 继续膨胀 | 按玩家旅程逐屏提取；领域写入只走命令 |
| 兼容字段恢复双权威 | 迁移测试保留，UI/领域禁止读取旧入口语义 |
| 失败变成等待税 | 战后完全无损、最低产能、可重复战果和明确恢复 CTA |
| 工厂变成领菜页 | 建造选址、成长效率、研究突破、派驻与容量形成选择 |
| Meta 抢占首章注意力 | 关卡/等级双门禁，1-5 后再开放长期招募与战令 |
| 自动测试制造虚假完成感 | 真人、真机、生产源和法律证据保持独立门禁 |
| 首包过大 | 字符清单驱动字体裁剪，保留真实中文覆盖和许可证 |

## 推荐后续提交序列

1. `build: subset runtime CJK font reproducibly`
2. `test: add private-storage and Firefox Web evidence`
3. `fix: iterate first-session friction from blind playtests`
4. `release: freeze production-origin candidate and rollback evidence`

每个提交必须可解析、可运行 focused test，不混入无关资产、凭据或未获授权商业功能。
