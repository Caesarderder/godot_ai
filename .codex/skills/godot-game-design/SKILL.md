---
name: godot-game-design
description: Use for Godot player-facing rules, loops, levels, balance, narrative, economy, UX intent, rewards, or genre design. Do not use for runtime bugs or technical implementation of those systems. Route through one knowledge-map axis and only the smallest relevant leaves.
---

# 策划

本岗位拥有：玩家规则、循环、关卡、数值、叙事、经济、UX 意图与类型差异。

不负责：Godot 实现路由程序，视觉实现路由美术，试玩与发布证据路由测试发布。

先读 [岗位地图](map/index.md)，只选择一个初始轴：[阶段](map/stages.md)、[类型](map/genres.md)、
[系统](map/systems.md) 或 [实践](map/practices.md)。随后只打开一到两个匹配 leaf。只有 leaf
直接链接时，才读取脚本、场景、模板或资产。

按玩家体验结果选择 leaf；遇到实现、运行时修复或资产生产时只记录 handoff，不预加载其他岗位。
相邻职责以 scope guard 区分，例如数值模型不等于伤害代码 bug，叙事设计不等于对话运行时修复。

任务改变 accepted 规则、数值语义或 acceptance criteria，或发现文档与行为冲突时，只读
[策划契约 preflight](map/contract.md) 定位相关项；不因此预加载制作人或全部项目文档。

## 风险与工件升级

选 leaf 前只判断工程成熟度、请求结果、最高风险声明和现有 owner/pattern，不启动问卷。先选
一个 leaf，第二个只解决不同阻塞风险。读完 leaf 的完整 `REFERENCE.md` 后，仅对实现、修复或
具体生产结果，且直接工件命中最高风险、工程又没有同等强的已验证模式时，才按 focused
test/demo、GDScript/scene/resource prototype、template/config、conceptual reference 的顺序打开
最多三个工件。正文要求 adaptation 前审查 prototype 时，至少打开一个，否则记录拒绝全部候选
的具体兼容性或项目适配理由。

编辑前记录 `adapt`、`reject` 或 `guidance-only` 及原因；只读索引不算使用示例。缓存本轮已读
文件，不重复读取未变内容；只跟随 wrapper/current `content_home`。内部 `SKILL.md` 失败时回到
wrapper 和已安装 `REFERENCE.md`，不猜 legacy 路径，不批量打开 scripts bundle。

Do not load every axis, invent a mandatory production workflow, or treat preserved reference-only
material as approved for the Godot 4.6.x GDScript Web Compatibility single-thread target.
