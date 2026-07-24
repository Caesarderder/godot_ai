---
km_id: invariant.project-boundaries
km_type: invariant
domain: cross-domain
status: active
owner: maintainers
last_verified: 2026-07-23
source_of_truth:
  - .omx/specs/deep-interview-fantasy-idle-expedition.md
  - .omx/plans/prd-fantasy-idle-expedition.md
validated_by:
  - ralplan-consensus
  - manual-plan-review
tags:
  - risk:product-drift
  - risk:state-consistency
related:
  - reference.product-boundaries
  - reference.state-command-lifecycle
---

# 项目不变量

## 产品不变量

- 手机端、单机、休闲放置；以 Web 游戏发布并主要在手机浏览器运行，玩家通过随机英雄培养和编队跨过卡点。
- P0 是英雄培养与编队，P1 是装备，P2 是薄营地。
- 大小任务只引导与奖励，不作为关卡硬锁。
- 英雄是随机运行实例，不回退为固定角色抽卡。
- 未经用户确认，不改变核心循环、系统主次、随机英雄模型、美术主题、商业化、目标平台或单机边界。

## 技术不变量

<<<<<<< HEAD
- `project-a/` 是当前 Godot 4.6.3 实现根；使用 GDScript、3D 表现、Web-first 发布。`taptap/` 是历史参考，不是当前交付入口。
- PRD/Test Spec 的玩法、经济和验收约束保持有效；其中旧版本、2D、Mobile renderer 与 Android-first 平台描述由 ADR-0005 取代。
- Web 使用 Compatibility / WebGL 2.0；默认单线程导出。Forward+、C#、原生移动插件和没有 Web 构建的 GDExtension 不得成为当前版本依赖。
- 3D 场景只投影领域战斗；物理、导航、动画和帧率不得决定命中、伤害、掉落或胜负。
- UI 必须适配浏览器 viewport、安全区和 DPI，主要触控目标不得低于 48 基准像素。
=======
- `project-a/` 是当前 Godot 4.7.1 实现根；玩法、资源、测试和工具分别进入 `project-a/game/**`、`project-a/tests/**` 与 `project-a/tools/**`。
- `project-a/addons/godot_ai/**`、EditorPlugin 和 `_mcp_game_helper` Autoload 是受保护工具层，默认不得被玩法任务修改、格式化或清理。
- Godot Mobile renderer、手机端、纯 2D 优先；安全区、返回键、触控尺寸和移动生命周期必须以 Godot 实现与设备证据闭环。
- `taptap/` 是保留的 Maker 2D 参考原型，不是默认实现根；其玩法和表现可以提炼为需求或测试，不得直接当作 Godot 已实现事实。
>>>>>>> origin/codex/toilet-man-3d-idle
- 静态定义与运行实例分离；运行状态只保存稳定 ID 和实例字段。
- executor 是 GameState 唯一写入口；价值命令先持久化再报告成功。
- 离线收益只认 `offline_anchor_unix`；战斗只认稳定 seed 和 5Hz tick。
- UI 是状态投影，不直接修改领域状态。
<<<<<<< HEAD
- 浏览器后台不依赖持续 Tick；恢复只通过 sealed internal command 结算离线收益。
=======
- 父仓库 Git 管理 `project-a/`；只有明确维护 `taptap/` 参考原型时，Maker 状态、提交、推送、预览和构建才走 TapTap MCP。
>>>>>>> origin/codex/toilet-man-3d-idle
- 实现事实必须由代码、测试和命令重新验证；计划路径不等于已存在路径。
