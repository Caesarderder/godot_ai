---
km_id: map.skills
km_type: map
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-25
source_of_truth:
  - .codex/skills
  - .codex/skills/docs-hunter/SKILL.md
  - .codex/skills/caesar-docs/SKILL.md
validated_by:
  - manual-skill-catalog-review
  - command:enumerate-project-skills
tags:
  - workflow:skill-routing
  - quality:task-routing
related:
  - map.control-index
  - map.workflows
  - workflow.skill-routing
  - invariant.project-boundaries
---

# Skill 能力地图

本页把 `.codex/skills/*/SKILL.md` 的当前能力目录接入知识地图。它负责“为任务选择哪项能力”，不替代项目事实、实现归属、产品约束或各 Skill 自身的完整说明。

## 使用原则

1. 非平凡仓库任务先用 `docs-hunter` 读取最小知识链，再按 [KM:workflow.skill-routing](../workflows/skill-routing.md) 选择主 Skill。
2. 优先选择最具体的领域 Skill；跨系统任务才使用 `gd-agentic-*` 或 `godot-master` 这类聚合入口。
3. 每次先确定一个主 Skill，只有确有跨域依赖时才增加辅助 Skill，避免同义 Skill 同时给出冲突方案。
4. Skill 描述中的引擎版本、渲染器、平台和语言只是能力适用条件；项目真实约束以 [KM:invariant.project-boundaries](invariants.md)、当前配置和代码为准。
5. 标注“显式调用”的设计/交付 Skill，不从普通实现请求自动推断。
6. 选中后必须完整读取对应 `SKILL.md`；本页不能代替其执行契约。

## 能力簇

| 能力簇 | 首选入口 | 当前具体 Skills |
|---|---|---|
| 文档与任务控制 | `docs-hunter` | `docs-hunter`、`caesar-docs`、`caesar-godot-skills`、`using-godot-prompter` |
| Godot 聚合路由 | 与任务维度匹配的 `gd-agentic-*` | `godot-master`、`gd-agentic-foundations`、`gd-agentic-2d-systems`、`gd-agentic-3d-systems`、`gd-agentic-dimension-adaptation`、`gd-agentic-gameplay-systems`、`gd-agentic-genre-blueprints`、`gd-agentic-ui-ux`、`gd-agentic-web-runtime` |
| 工程基础与架构 | `godot-architecture` | `godot-project-setup`、`godot-architecture`、`scene-organization`、`component-system`、`dependency-injection`、`event-bus`、`resource-pattern`、`gdscript-patterns`、`gdscript-advanced`、`godot-best-practices`、`godot-gdscript-patterns`、`godot-brainstorming` |
| 2D/3D 与运行时表现 | 最具体的系统 Skill | `2d-essentials`、`3d-essentials`、`player-controller`、`camera-system`、`physics-system`、`ai-navigation`、`ai-perception`、`animation-system`、`tween-animation`、`particles-vfx`、`shader-basics`、`math-essentials`、`procedural-generation`、`state-machine` |
| 玩法与状态系统 | 最具体的玩法 Skill | `ability-progression`、`ability-system`、`combat-system`、`game-economy`、`inventory-system`、`dialogue-system`、`narrative-runtime`、`objective-loop`、`rule-resolution`、`rhythm-gameplay`、`save-load` |
| UI、输入与内容生产 | `ux-design` 或具体实现 Skill | `godot-ui`、`responsive-ui`、`hud-system`、`input-handling`、`localization`、`ux-design`、`game-visual-design`、`builda-vector-art`、`assets-pipeline`、`audio-system` |
| 调试、测试、性能与发布 | 与验证阶段匹配的 Skill | `godot-debugging`、`godot-testing`、`godot-code-review`、`godot-optimization`、`export-pipeline`、`game-web-release`、`game-playtest` |
| 显式设计与交付 | 用户明确指定的 `game-*` | `game-design`、`game-balance`、`game-level-design`、`game-narrative-design`、`game-technical-design`、`game-prototype`、`game-vertical-slice` |
| 条件能力与替代技术栈 | 先检查项目边界 | `addon-development`、`beehave`、`limboai`、`csharp-godot`、`csharp-signals`、`gdextension`、`multithreading`、`mobile-development`、`multiplayer-basics`、`multiplayer-sync`、`dedicated-server`、`xr-development` |

## 高频任务路由

| 任务信号 | 主 Skill | 常见辅助 Skill | 开始前必须确认 |
|---|---|---|---|
| 修改 GDScript 或节点生命周期 | `gdscript-patterns` | `godot-architecture`、`godot-testing` | 归属文件、引擎版本、测试入口 |
| 新建或拆分场景/系统 | `godot-architecture` | `scene-organization`、`component-system` | 状态所有权、依赖方向、Autoload 边界 |
| 战斗、数值、能力、装备 | 对应玩法 Skill | `resource-pattern`、`save-load`、`godot-testing` | 确定性、持久化写入口、产品领域不变量 |
| 2D/3D 表现或交互 | `2d-essentials` / `3d-essentials` | 相机、动画、物理、VFX 的具体 Skill | 表现是否影响领域结果、Web 预算 |
| HUD、菜单、响应式布局 | `ux-design` 或 `godot-ui` | `responsive-ui`、`hud-system`、`input-handling` | 玩家目标、触控/安全区、信息优先级 |
| Bug、回归或性能问题 | `godot-debugging` / `godot-optimization` | `godot-testing` | 可复现证据、基线、最小验证命令 |
| Web 构建或发布 | `export-pipeline` | `gd-agentic-web-runtime`、`game-web-release` | 构建就绪、产物验证、线上验证三种状态 |
| 更新知识地图 | `caesar-docs` | `docs-hunter` | 受影响节点、索引、反向链接、lint |

## 条件与冲突处理

- `godot-master` 面向 Godot 4.7+，多数项目专用 Skill 面向 Godot 4.6 Web；出现版本冲突时，先读取实际 `project.godot` 和项目 ADR，再选匹配版本的 Skill。
- `csharp-*`、`gdextension`、`multithreading`、`mobile-development`、多人/服务器和 XR 能力仅表示目录中存在这些知识，不表示当前项目已经授权采用这些技术。
- `beehave` 与 `limboai` 是替代 AI 技术路线；必须先确认插件已安装、目标平台可用且没有违反 Web/GDExtension 约束。
- `dialogue-system` 与 `narrative-runtime`、`ability-system` 与 `ability-progression` 等相邻 Skill，按“设计数据模型/通用组件”与“当前运行时/成长实现”的实际边界选择，不默认双开。
- 如果 Skill 默认值与代码、配置、测试或知识地图冲突，保留冲突并停止扩张；回到 [KM:workflow.knowledge-query](../workflows/knowledge-query.md) 核实事实。

## 维护

新增、删除、重命名或同步 `.codex/skills/*` 后，运行 [KM:workflow.knowledge-map-maintenance](../workflows/knowledge-map-maintenance.md)：重新枚举含 `SKILL.md` 的直接子目录，更新本页能力簇和任务路由，并执行 [CMD:docs-lint](../runbooks/docs-lint.md#docs-lint)。

