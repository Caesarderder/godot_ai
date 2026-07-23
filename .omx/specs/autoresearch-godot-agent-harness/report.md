# Godot Agent-First 游戏开发 Harness 研究报告

日期：2026-07-21  
基线：Godot 4.7.1 stable  
状态：独立架构评审已批准

## 1. 结论

Godot 适合构建 agent-first 游戏工程，但成功条件不是让 Agent 获得更多编辑器权限，而是让游戏工程变得可读、可控、可重放、可观察、可判定。

建议采用一个薄 Harness，复用 Godot 本体、现有 `godot_ai` MCP 插件和项目测试，而不是另造场景解析器或全能游戏生成器：

```text
人类意图
  -> Planner：产品规格 / feature backlog
  -> Sprint Contract：一个纵向行为 + 明确验收
  -> Generator：小步修改
  -> Godot Adapter：import / parse / test / run / input / capture / export
  -> Evidence Bundle：状态、日志、测试、截图、性能、diff
  -> 独立 Evaluator：逻辑门 + 视觉 rubric + 架构规则
  -> pass / 带证据返工 / 人工升级
```

推荐第一款 Harness 样板游戏是 **2D 单屏格子回合制战术 roguelite**，而非 3D、平台跳跃或实时动作。它能同时覆盖 Godot 的 Scene、Node2D、Resource、Signal、Control、Tween、音频、存档和导出，又可将核心游戏完整建模为确定性状态转换。

## 2. 事实、推断与边界

### 已验证事实

- 官方当前稳定版为 Godot 4.7.1，发布于 2026-07-14；4.8 仍为开发版。[Godot 版本归档](https://godotengine.org/download/archive/)
- Godot CLI 原生支持 headless、import、脚本解析、单场景运行、固定帧录制、性能报告和命令行导出。[Godot 4.7 CLI](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- TSCN 是基本可读并适合版本控制的文本场景格式；但默认值、注释和格式可能被编辑器重写，所以 Godot 本体必须是最终解析权威。[TSCN 格式](https://docs.godotengine.org/en/4.7/engine_details/file_formats/tscn.html)
- `project-a/addons/godot_ai/` 已暴露 43 个 server-facing tools，覆盖场景、节点、脚本、资源、测试、运行时输入、日志和截图等领域。
- `project-a/tools/verify_m1.ps1` 已在本次研究中重复执行并通过：Godot 4.7.1 编辑器导入、Mobile 启动、Compatibility 启动，以及 96/96 GUT tests、9135 assertions。命令、退出码、脚本摘要和运行前后状态摘要见 [verification-evidence.json](verification-evidence.json)。第二次证据化执行前后 worktree status hash 与 `project.godot` hash 相同；第一次执行前没有持久化 baseline，因此不把第一次运行作为独立可信证据。

### 仓库边界

- 当前产品主实现仍是 `taptap/`；`project-a/` 在知识地图中被定义为历史 Godot 基线。
- 本报告是新 Godot Agent-first 工程的架构建议，不代表授权把当前玩法开发静默迁回 Godot。
- 如果要在本仓库正式恢复 Godot 主线，应先写 ADR、更改项目不变量和实现索引。

### 研究推断

OpenAI 的实践强调：仓库知识是系统记录、给 Agent 地图而非巨型手册，并让 UI、日志和指标对 Agent 可读；Anthropic 的研究强调：把工作拆成可处理块、以结构化 artifact 交接，并把 Generator 与 Evaluator 分离。[OpenAI Harness Engineering](https://openai.com/index/harness-engineering/)、[Anthropic 长时应用 Harness](https://www.anthropic.com/engineering/harness-design-long-running-apps)

把这些原则应用到游戏开发时，额外需要两个 Web 应用通常没有的 oracle：**确定性模拟重放**和**固定条件下的视听证据**。

## 3. 为什么推荐格子回合制

| 类型 | 可生成性 | 确定性 | 视觉验收 | 低资产依赖 | 自动测试 | 判断 |
|---|---:|---:|---:|---:|---:|---|
| 2D 格子战术 roguelite | 5 | 5 | 4 | 4 | 5 | 最佳首作 |
| 卡牌构筑 | 5 | 5 | 3 | 5 | 5 | 容易内容/UI 膨胀 |
| Survivors-like | 4 | 2 | 5 | 4 | 2 | 实时密度和平衡易抖动 |
| 精确平台跳跃 | 3 | 2 | 5 | 3 | 2 | 手感很难自动断言 |
| 3D 动作/探索 | 2 | 1 | 4 | 1 | 1 | 组合面和资产成本过高 |

推荐概念《回路快递》：9×9 单屏设施；玩家机器人每回合移动或使用模块；敌人先显示意图；收集 3 个能源核心并抵达出口。首版只有 3 类敌人、4 个模块、5 个房间模板，单局 8–12 分钟。

硬范围预算：

- 2D、单机、单屏、首版键鼠；
- 整数格坐标，最多 12 个同屏实体；
- 无刚体、无导航网格、无联网、无外部后端；
- shader 只能锦上添花，不可成为玩法依赖；
- 不超过 15 个生产脚本、10 个场景、20 个数据 Resource、5 个核心系统。

## 4. Godot 专属架构

### 4.1 规则层必须脱离 SceneTree

```text
Command
  -> Simulation.apply(command)
  -> Canonical GameState
  -> Array[DomainEvent]
  -> Presentation Adapter
  -> Node2D / Control / Tween / Audio
```

- `GameState` 使用稳定实体 ID、整数坐标、明确 phase enum 和可序列化 primitive graph。
- 规则对象优先 typed GDScript `RefCounted`；设计师配置使用只读的自定义 `Resource`。
- SceneTree 负责生命周期、输入与表现，不是真值数据库。
- 表现层消费 DomainEvent，不得反向写模拟状态。
- 核心规则禁止依赖 `_process(delta)`、Tween、动画回调或物理碰撞。

Godot 官方建议不要为一切创建 Node，并将 RefCounted/Resource 作为轻量对象和可序列化数据选择。[Node alternatives](https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html)

### 4.2 确定性合同

每局保存：

```json
{
  "schema_version": 1,
  "engine_build": "4.7.1.stable.official.a13da4feb",
  "content_sha256": "...",
  "rng_contract": "godot_rng_same_build_v1",
  "seed": 123456,
  "actions": [],
  "final_state_hash": "..."
}
```

- 随机性只来自注入的独立 `RandomNumberGenerator`。普通 replay 只接受 `seed`：先创建 RNG，再执行 `rng.seed = replay.seed`，由 seed 唯一派生初态，禁止从 replay 注入任意 `rng.state`。Godot RNG 算法属于实现细节，所以 `godot_rng_same_build_v1` 的可比范围严格限制为相同 Godot build、内容摘要和平台数值模型；如需跨版本 replay，改用仓内版本化 PRNG。
- 只有 checkpoint/resume 可额外保存 `rng_state`，且该值必须是在相同 engine build 下设置 seed 并推进模拟后，从该 RNG 实例的 `rng.state` 实际读取；无 checkpoint 时字段省略或为 `null`，绝不使用 `0` 等占位值。恢复顺序固定为设置 seed、验证 checkpoint 元数据、再恢复此前读取出的合法 state。
- canonical JSON 只允许 null、bool、UTF-8 string、范围受限 integer、array 与 string-key dictionary；禁止 float、Object、Resource、NodePath 和 Variant 特殊值。
- dictionary key 按 UTF-8 byte lexicographic order 排序；实体 array 按稳定 ID 排序；事件按 `(turn, phase, sequence)` 排序；enum 编码为固定小写字符串；缺省字段必须显式写出。
- JSON 使用 UTF-8、无 BOM、无无关空白；`final_state_hash = SHA-256(canonical_json_bytes)`。
- 同 engine build、content digest、seed 和 action list 必须产生相同 event transcript 与最终状态 hash；checkpoint resume 则额外要求相同的已验证 checkpoint RNG state。
- 不把 NodePath、instance ID、Resource 实例或 float 时间写进 canonical state。
- 数据 Resource 与运行时实例分离，防止共享 Resource 被误改。
- replay 门禁至少包含：同进程重复、两个冷启动进程重复、save round-trip 后继续、旧 schema migration golden；未知未来 schema 必须拒绝，旧 content digest 默认拒绝，除非有显式迁移器。

[RandomNumberGenerator API](https://docs.godotengine.org/en/4.7/classes/class_randomnumbergenerator.html)

### 4.3 场景关系

- 场景尽量自包含、单一职责。
- 父层注入依赖并向下调用；子场景通过 Signal 向上报告。
- sibling 由共同祖先协调。
- Autoload 只保留真正跨场景的少量基础设施。

[Godot 场景组织最佳实践](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html)

### 4.4 目录建议

```text
game/
  project.godot
  AGENTS.md
  docs/
    index.md
    product.md
    architecture.md
    verification.md
    error_patterns.md
  features/
    board/       # scene + script + resources + tests
    player/
    enemies/
    modules/
    run/
  simulation/    # canonical state, commands, reducers, replay
  presentation/  # event projection, theme, audio, animation
  app/           # composition root, menus, save, settings
  addons/        # pinned vendor dependencies
  tests/
    unit/
    integration/
    fixtures/
    visual/
  harness/
    contracts/
    adapters/
    rubrics/
    artifacts/
```

按 feature 共置资源、场景和脚本，小写 `snake_case` 文件名，符合官方项目组织建议。[Project organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html)

## 5. Harness 六层设计

### 5.0 可信计算边界

Generator 不能同时掌握实现、oracle 和判决。每轮在编码前冻结：

- 起始 Git SHA、完整 dirty/untracked baseline 的 SHA-256；
- sprint contract canonical JSON 与 SHA-256；
- Godot binary、adapter、runner、plugin/server、acceptance tests、golden、rubric 和 evaluator digest；
- `allowed_paths` 与 `protected_paths`。

默认保护：`addons/**`、`harness/adapters/**`、`harness/evaluator/**`、`harness/rubrics/**`、`tests/acceptance/**`、`tests/golden/**` 和当轮 `artifacts/**`。Generator 可新增 feature-local tests，但它们只提供开发反馈，不能替代受保护 acceptance tests。Generator 对 evidence 目录只有通过 adapter 触发生成的权限，不能直接创建、修改或删除 verdict 和证据。

Evaluator 在独立进程中运行，挂载受保护规则为只读，重新执行验证并核对所有 digest；最终 `verdict.json` 只能由 Evaluator 写入。需要改变 golden、rubric、contract 或 protected paths 时，本轮返回 `human_judgment_required`，经单独审批后开启新合同，禁止同轮偷偷更新基线。

### 5.1 Knowledge Map

`AGENTS.md` 只做短路由，不做百科全书。详细知识拆成小节点：

- 产品不变量；
- 领域术语与状态模型；
- 文件 ownership；
- 场景关系和信号方向；
- 常用工作流；
- 验证矩阵；
- 已确认错误模式。

每个 sprint 开始时只加载相关节点。所有文档必须记录事实源与最近验证日期。

### 5.2 Sprint Contract

Agent 不能接收“实现战斗系统”这种任务。合同必须是一个纵向、可见、可测试行为：

```yaml
goal: 添加推击模块
allowed_paths:
  - features/modules/**
  - simulation/**
  - tests/features/modules/**
forbidden_paths:
  - addons/**
  - harness/**
  - tests/acceptance/**
  - tests/golden/**
acceptance:
  - 三个规则用例通过
  - 固定 replay 得到指定 state hash
  - 演示场景可启动
  - 视觉 rubric 通过
artifacts:
  - test-report.json
  - replay.json
  - screenshot.png
```

Generator 与 Evaluator 在编码前协商合同；修改范围、完成证据和人工升级条件必须显式。

### 5.3 Godot Command Adapter

不要让 Agent 任意拼命令；提供结构化、版本化 adapter：

1. 环境门：`godot --version` 和 `godot --help`，校验锁定的 4.7.1 与 capability map。Godot 对未知参数可能静默忽略，不能只看启动成功。
2. 导入门：`godot --headless --path <project> --import`。
3. 解析门：对变更脚本使用 `--script ... --check-only`；它不是项目全量编译，不能代替后续门禁。
4. 行为门：仓内测试 runner 或 GUT/GdUnit adapter，必须返回非零失败码和 JSON 报告。
5. 场景门：运行指定场景、限制帧数、记录独立日志。
6. 视觉门：固定 seed、resolution、FPS 和输入序列，等待 `RenderingServer.frame_post_draw` 后截图；必要时 `--write-movie`。
7. 发布门：命令行 debug/release export + 导出产物 smoke。

官方 `--test` 面向 Godot 引擎源码 doctest，不是游戏项目通用测试入口，因此 Harness 不应假设 stock Godot 自带项目单测框架。[Godot unit testing](https://docs.godotengine.org/en/4.7/engine_details/architecture/unit_testing.html)

### 5.4 Live Editor Adapter

现有 `godot_ai` MCP 可以承担 Act 与 Observe：

- 查询编辑器、场景树和属性；
- 创建/修改 scene、node、script、resource；
- 运行项目、发送键鼠/手柄输入；
- 读取 editor/game 日志；
- 获取 2D、3D、game 和 cinematic screenshot。

但其定位应是薄适配器：

- `@tool`/EditorPlugin 运行在编辑器进程内，官方明确警告错误操作可能破坏场景甚至使编辑器崩溃。[Running code in editor](https://docs.godotengine.org/en/4.7/tutorials/plugins/running_code_in_the_editor.html)
- `game_eval` 等任意代码执行能力默认关闭，只允许受信本机、临时 debug run 和单独 capability gate。
- 正常工作流使用 curated commands，不把自由 eval 当主接口。
- `addons/godot_ai/**` 作为 pinned vendor；普通 gameplay sprint 禁止修改。

### 5.5 Evidence Bundle

每次迭代保存：

```text
artifacts/<sprint-id>/
  manifest.json       # start SHA, dirty baseline, contract/tool digests
  diff.patch
  import.log
  parse.log
  test-report.json
  replay.json
  state-before.json
  state-after.json
  game.log
  screenshots/
  benchmark.json
  verdict.json
```

证据必须由受控 adapter 和独立 Evaluator 生成，不能由 Generator 用自然语言宣称或直接覆写。manifest 必须列出每个命令的 argv、开始/结束时间、退出码与产物 SHA-256。

### 5.6 Independent Evaluator

按以下顺序判定，任何硬门失败都停止：

1. Scope：是否只改 allowed paths，是否触碰 vendor 或用户改动。
2. Import/parse：Godot 是否能冷导入和加载。
3. Unit/property：状态不变量、reducer 与序列化是否通过。
4. Replay：固定输入是否复现同 transcript/hash。
5. Scene smoke：是否启动、交互、退出且无新错误。
6. Visual rubric：结构探针、截图差异与独立视觉评分是否达到阈值。
7. Architecture：表现是否回写状态、是否新增不必要 Autoload/Node/global state。
8. Export：目标预设是否构建并启动。

Evaluator 必须与 Generator 分离，并输出 `approved`、`changes_required` 或 `human_judgment_required`，附具体证据路径。

最小 visual rubric v1 为机器可执行 JSON：

```json
{
  "environment": {
    "engine_build": "4.7.1.stable.official.a13da4feb",
    "renderer": "mobile",
    "viewport": [1280, 720],
    "locale": "zh_CN",
    "theme_sha256": "...",
    "font_sha256": "...",
    "seed": 42,
    "fixed_fps": 60
  },
  "probes": [
    {"id": "hud_visible", "kind": "node_property", "expected": true},
    {"id": "intent_icon_count", "kind": "integer", "min": 1},
    {"id": "critical_text_contrast", "kind": "wcag_ratio", "min": 4.5},
    {"id": "layout_bounds", "kind": "viewport_containment", "expected": true},
    {"id": "golden_ssim", "kind": "image_similarity", "min": 0.985}
  ]
}
```

截图必须在固定状态探针满足后等待 `RenderingServer.frame_post_draw`，并同时保存 scene/state snapshot。像素/SSIM 比较只在锁定 OS、renderer、GPU driver、字体、locale 和 viewport 的 canonical worker 上执行；其他环境只做结构探针并把差异交给独立视觉模型。视觉模型低置信度、与结构探针冲突或拟议更新 golden 时，返回 `human_judgment_required`。首版不比较音频波形；只验证 `DomainEvent -> audio cue id -> expected bus` 的事件映射和总线配置，因此本文将验收证据称为“逻辑、视觉与音频事件证据”。

## 6. 现有 `project-a` 的复用与缺口

### 可直接复用的模式

- `godot_ai` 的 loopback、token、路径限制、结构化 handler error、日志、截图和游戏输入。
- `verify_m1.ps1` 的 import + 双渲染器 smoke + 递归 GUT。
- command fingerprint、executor、receipt ledger、保存恢复和 deterministic battle。
- “纯 reducer + durable command + deterministic simulation”作为玩法内核范式。

### 必须补齐

1. 知识地图已漂移：文档仍把 Godot 描述为 M0/M1，而代码和测试明显更靠后。开始 Agent 工作前先重建事实索引。
2. 当前 MCP `test_run` 只发现 `tests/` 顶层的自有 suite，不能直接运行深层 GUT；短期以 CLI GUT 为真值，长期增加明确的 `gut_run` adapter。
3. 本地插件是 vendor copy，但 Python server 由 `uvx` 获取；需锁定 hash、缓存或 vendor，补齐离线/供应链可复现。
4. batch rollback 只保证 UndoRedo action，文件写入不是事务；混合 batch 不得宣称 atomic。
5. `game_eval` 风险接近远程代码执行；保持 loopback、token、默认禁用和可审计授权。
6. 插件启用可能修改 `project.godot` 注册 autoload；启动前后都要记录 worktree baseline。
7. 冻结当前未跟踪 tests/fixtures 后，才能把 96 tests 当稳定项目门禁。

## 7. 纵向里程碑

- **M0 Harness skeleton**：锁定 Godot；一条命令完成 version/import/parse/test/smoke；生成 evidence bundle。
- **M1 Walking toy**：9×9 棋盘、四向移动、墙、核心、出口、重开；固定动作得到固定位置与截图。
- **M2 Tactical turn**：玩家动作、敌人意图、敌人结算、HP、胜负；输出 state snapshot 和 event transcript。
- **M3 Data-driven content**：3 敌人、4 模块、5 房间模板全部 Resource 化；同 seed+actions 结果一致。
- **M4 Product feel**：HUD、意图图标、高亮、Tween、音频、暂停与重开；表现只消费事件；固定场景截图评分。
- **M5 Short-run loop**：房间序列、三选一升级、结算、设置、versioned save、Windows Desktop export smoke；Web 先只验证 export artifact build。到此停止扩展。

每个里程碑始终保持可玩、可合并和可交接，禁止建立长期无法运行的“大爆炸分支”。

## 8. 失败恢复与持续改进

- 每轮开始：读任务状态、git status、知识路由、上一轮 verdict，并运行最小 smoke。
- 每轮结束：所有硬门通过，写 progress/handoff artifact；未通过则不得标记 feature complete。
- 三次相同失败后停止重试，生成 failure packet 并请求人工判断。
- 每次发现重复错误，把解决方案升级为 lint、schema、测试、adapter 或知识节点，而不是只增加 prompt 文本。
- 周期性冷启动：删除可重建 `.godot/` cache 后重新 import，防止缓存掩盖问题；源文件旁 `.import` 配置提交，`.godot/` 不提交。[Godot import process](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html)

## 9. 最小落地优先级

第一阶段不要开发新大插件，只做五个薄层：

1. `harness.json`：版本、路径、预算和 capability policy。
2. `verify.ps1`/`verify.sh`：统一官方 CLI 与 GUT，输出 JSON。
3. `replay_runner.gd`：读取 seed/actions，输出 transcript/hash。
4. `capture_scenario.gd`：固定场景、输入、等待条件和截图。
5. `evaluate.py` 或等价 evaluator：读取 artifact，不直接相信 Generator 总结。

这五层完成后再考虑新增 MCP tool。对该工程而言，真正的杠杆来自可靠反馈，而不是更多生成权限。

首个 canonical 发布矩阵只包含 Windows Desktop：Godot 4.7.1 official、Mobile renderer、固定 export preset 与 export-template SHA-256。smoke runner 启动导出的 exe，限定超时，执行固定输入序列，并要求进程成功退出、game log 无 ERROR、关键资源全部加载、最终探针为 `main_menu_ready` 或指定玩法状态。Web 只有在补齐本地 HTTP server、浏览器自动化、console error、资源请求失败、超时和页面状态探针后，才能从“artifact build”升级为“runtime smoke”。

## 10. 完成定义

一个 vibecoding feature 只有同时满足以下条件才是完成：

- Godot 锁定版本可冷导入；
- 改动范围符合 sprint contract；
- 规则测试和确定性 replay 通过；
- 真实场景可由 Agent 启动和交互；
- 日志没有新增错误；
- 视觉与音频事件证据达到锁定 rubric；
- canonical Windows Desktop 导出和 runtime smoke 通过；其他目标只能报告其实际达到的 build/smoke 层级；
- 独立 Evaluator 批准，并且所有证据都能从 artifact 路径复查。

这才是“通过 vibecoding 做游戏”的工程化定义：人负责意图、边界和品味，Agent 负责实现与迭代，Harness 负责让错误暴露并阻止伪完成。
