---
km_id: reference.toilet-factory-refactor-plan
km_type: reference
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-26
source_of_truth:
  - docs/game-contract.md
  - docs/references/product-design/skibidi-toilet-idle-siege-gdd.md
  - docs/references/architecture/toilet-factory-technical-design.md
validated_by:
  - manual-producer-plan-review-2026-07-26
tags:
  - workflow:implementation-plan
  - risk:major-migration
related:
  - reference.toilet-factory-technical-design
  - reference.verification-matrix
  - reference.first-30m-contract
---

# 永久军团 SLG 大重构实施计划

执行状态：`READY / NOT STARTED`。新策划已接受，当前 schema v6 仍是消耗单位旧实现。
计划按可运行纵切推进，不允许先把所有页面重画后再补领域规则。

## 总体交付策略

每个阶段都遵循：

1. 先写目标合同的 focused test；
2. 建立或迁移领域权威；
3. 接入命令和存档；
4. 接 view model/UI；
5. 跑旧内核回归与新合同验证；
6. 更新实现状态，不把规划写成完成。

明确复用：

- 3D 城市、三段攻城、角色模型、战斗事件与 25 关内容骨架；
- `CommandExecutor`、存档主备、revision/fingerprint/receipt；
- Web Compatibility 配置、设置、音频和失焦暂停；
- `StageCatalog`、任务/成就中仍符合新经济的结构。

明确替换：

- 可消耗库存单位、永久阵亡、一键补位；
- 型号科技作为唯一成长；
- 单位生产队列、废料恢复线；
- 马桶钻图纸研发、保底和当前 P0 商业入口；
- 围绕“制造/研发/补位”的 App Shell 信息架构。

## 阶段 0：冻结合同与建立迁移护栏

### 代码/数据

- 为新 schema 创建 fixture 和迁移测试，不立即覆盖真实存档；
- 为 v6 存档生成不可变 golden samples；
- 列出 legacy 命令、字段、页面和测试的保留/迁移/删除矩阵；
- 新增 feature flag 或独立测试入口，让新领域纵切可在不破坏旧 shell 的情况下运行。

### 策划/UX

- 锁定四角色、三星、六设施、三资源、四城镇、一个 Boss；
- 产出低保真流程图：标题 → 工厂 → 军团 → 战区关卡详情 → 战斗 → 结算 → 维修/下一关；
- 为资源、战备度、维修和设施状态建立统一术语。

### 退出条件

- `docs/game-contract.md` validator 与 docs lint 通过；
- v6 golden save 可加载、备份和回滚；
- 每个旧字段有明确迁移决策；
- 不存在仍未决定且会改变 schema 的 P0 规则。

## 阶段 1：永久角色与新经济内核

### 代码框架

- 重构 `HeroState`：永久身份、level/xp/star/readiness、技能和派驻；
- 重构 `EconomyState`：gold、industrial_tech、skill_chips、breakthrough_items；
- 将六槽 formation 改为引用永久 `hero_id`；
- 新增角色目录和三星节点数据；
- 新增升级、升星、编队、派驻命令与 query model；
- 保留 candidate-save-commit 和 receipt。

### 玩法

- 四名角色各有一个主动技能、一个被动、一个工厂专长；
- 等级提供稳定数值，星级提供机制节点；
- 零 readiness 拒绝出战，非零可带伤出战。

### 验证

- 新档角色唯一、升级/升星边界、经验归属、技能解锁；
- 派驻唯一、六槽去重、零战备拒绝；
- 重复请求、余额不足、存档往返与确定性 combat power。

### 退出条件

纯 headless 状态下可执行“升级角色 → 解锁二星被动 → 编队 → 保存 → 重载”，结果完全一致。

## 阶段 2：设施生产、离线结算与维修

### 代码框架

- 建立 `FacilityCatalog`、`FactoryService` 时间结算和容量模型；
- 建立 `RepairService` 与 repair order；
- 实现陶瓷厂、零件车间、能源站、维修中心、研究所和指挥中心；
- 新增 claim、facility_upgrade、process_resource、quick_repair、full_repair、timed_repair 命令；
- 统一服务器无关的本地时间回拨保护。

### 玩法

- 基础资源自动生产，零件可由加工或战果补充；
- 快速整备、完全维修、等待维修至少两种先落地；
- 设施关键等级解锁功能节点；
- 派驻专长实际改变产能、容量或维修成本。

### 验证

- 0 秒、正常离线、超容量、时间回拨和 12 小时边界；
- 资源守恒、加工、容量、设施等级门禁；
- 局部/完全/计时维修、并发槽、重复领取；
- 全队重伤且金币为零时的最低恢复。

### 退出条件

测试存档能离线结算资源、升级设施、修复一名零战备角色并再次满足出战条件，无金币死锁。

## 阶段 3：战斗伤损与城镇战果纵切

### 代码框架

- 将 `BattleSession` 输入切为永久角色快照；
- 将 `dead_unit_ids` 替换为 `damage_manifest` 和 `xp_manifest`；
- `settle_battle` 原子写入战备度、经验、金币、工业技术和关卡进度；
- 迁移撤退、超时、失败和战报 reason code；
- 保留三段式攻城、核心巨炮和表现事件。

### 玩法

- 四关逐步展示轻伤、带伤推进、重伤/撤退和 Boss 整备；
- 战区关卡详情提供主要威胁与预计伤损区间，并允许直接出击；
- 胜利、失败和撤退有不同战果/伤损曲线；
- 已占领城镇只提供重玩和少量税收，不自动扫荡。

### 验证

- 相同 seed/快照结果一致；
- damage manifest 只包含出战角色且范围合法；
- 胜败撤退均 exact-once；
- 实时 HP 不被误作战备度；
- 表现层不改变结果；
- 跨 FPS digest 和 3D 投影回归。

### 退出条件

可 headless 完成“满状态进攻 → 惨胜 → 战备下降 → 快速整备 → 带伤再战 → Boss 胜利”。

## 阶段 4：UI 信息架构重构

### App Shell

将顶层导航重构为：

- 工厂；
- 军团；
- 战区；
- 目标；
- 设置作为二级入口。

为每个屏幕建立独立 presenter/view model，禁止继续在 `main.gd` 内直接拼接领域字段。

### 工厂页

- 顶部显示三资源、每分钟产量和存满时间；
- 设施卡展示等级、状态、派驻和下一功能节点；
- 维修区展示受损角色、方案、成本和时间；
- 主 CTA 根据可领取、容量将满、角色失能或可升级动态变化。

### 军团页

- 角色列表展示等级、星级、战力、战备度和职责；
- 详情页展示升级前后、星级路线、技能与工厂专长；
- 编队使用 `2×3` 槽位，拖放和点击替换均可用；
- 资源不足时指向真实获取来源。

### 战区页

- 地图保留五章结构，但第一切片只开放四城镇和 Boss；
- 城镇详情展示敌情、推荐战力、预计伤损、奖励和阵容；
- 开战按钮在角色失能时说明具体原因，不静默禁用。

### 战斗与结算

- HUD 聚焦阶段、核心、技能、撤退和伤损预警；
- 结算先讲结果，再讲成长和伤损；
- 根据状态只突出一个主 CTA：下一关、快速整备、查看维修或再战；
- 支持直接维修后继续，不强制返回工厂首页。

### 退出条件

844×390 下四个顶层屏幕、战前、战斗和结算无横向滚动、遮挡或不可达按钮；
新 UI 不再读取 legacy unit/blueprint/pity 字段。

## 阶段 5：UX 教学与首 30 分钟

### 渐进教学

- 第一次只教收资源和升级；
- 第一战后教战备度和快速整备；
- 第一次设施升级教“战果扩厂”；
- 第一次星级只解释一个新技能与一个工厂专长；
- 第一次高伤损关教撤退；
- 第一次失败教无死锁恢复，不弹出付费捷径。

### 内容节奏

- 1-1：满血获胜，轻伤；
- 1-2：解锁第二角色/设施功能；
- 1-3：带伤继续有价值；
- 1-4：高威胁，鼓励撤退或完整维修；
- 1-5 Boss：需要利用角色成长和工厂整备。

### 无障碍与反馈

- 颜色之外使用图标/文字表达伤损；
- 减少动态设置削弱镜头震动与闪光；
- 所有按钮保持移动触控尺寸；
- 中文字体、长文本、数字缩写和安全区通过；
- 维修时间和资源不足信息必须解释“为什么”和“怎么解决”。

### 退出条件

真人玩家无需口头指导完成首 30 分钟，并能复述双向循环、战备度和至少两种维修策略。

## 阶段 6：迁移、清理与 Web 门禁

### 存档迁移

- 正式启用目标 schema；
- v6 → 新 schema 原子迁移；
- 旧马桶钻/研发数据封存，不在 P0 UI 暴露；
- 迁移前生成备份，失败回滚；
- 删除运行时 legacy 分支前保留 golden test。

### 清理

- 移除单位生产、永久删除、一键补位和图纸研发入口；
- 删除不再可达的命令注册、UI 和测试；
- 保留确有迁移用途的 codec，不保留双权威；
- 更新文件归属、架构、实现状态、验证矩阵和 release checklist。

### 发布验证

- 全部 headless 套件；
- Web release export 与 artifact audit；
- 844×390 本地浏览器全流程；
- Android Chrome 和 iOS Safari；
- 20 分钟连续游玩、刷新/关闭恢复、离线结算、时间回拨；
- 真人首 30 分钟与最终 scope audit。

### 退出条件

新合同所有 acceptance criteria 有实现引用与独立验证证据；旧 P0 行为无玩家入口和运行时权威。

## 风险与控制

| 风险 | 控制 |
|---|---|
| `main.gd` 继续膨胀 | 阶段 4 引入 screen presenter/view model，领域写入只走命令 |
| v6/v7 双权威 | 一次迁移、golden save、明确删除日期 |
| 维修变成固定税 | 局部/完全/等待/带伤继续至少两种选择，并做真人观察 |
| 失败导致死锁 | 基础产能永久可用、基础维修不用金币、恢复时长设上限 |
| 工厂变成领菜页 | 设施功能节点、派驻、容量与维修调度共同构成决策 |
| 系统过多 | P0 只保留等级、三星、技能、一个工厂专长，不做装备/天赋套娃 |
| UI 改完规则仍不稳 | 领域纵切通过后才迁正式 App Shell |
| 旧测试“全绿”误导 | 验证矩阵明确区分 legacy baseline 与新合同证据 |

## 推荐提交序列

1. `docs: accept permanent-hero factory logistics contract`
2. `test: add v7 hero economy migration fixtures`
3. `refactor: establish permanent hero and formation authority`
4. `feat: add facility production and repair domain`
5. `refactor: settle battle damage instead of permanent casualties`
6. `feat: rebuild factory and legion screens`
7. `feat: rebuild campaign prebattle and settlement UX`
8. `test: cover first-30m loop and web lifecycle`
9. `chore: migrate saves and remove v6 gameplay authority`

每个提交必须可解析、可运行 focused test，并且不混入无关资产或商业化功能。
