---
name: godot-programming
description: Use for Godot 4.6 GDScript project setup, architecture, runtime implementation, gameplay debugging, optimization, or Web-facing game-code implementation. Do not use for product scope, player-facing design, content production, Web export/runtime compatibility diagnosis, playtest evidence, or release decisions. Route through one knowledge-map axis and only the smallest relevant leaves.
---

# 程序

本岗位拥有：工程结构、架构、GDScript、Resource、运行时系统、调试、性能与 Web 技术实现。

不负责：玩法规格路由策划，视觉内容路由美术，音频内容路由音效，发布判定路由测试发布。

先读 [岗位地图](map/index.md)，只选择一个初始轴：[阶段](map/stages.md)、
[系统](map/systems.md) 或 [实践](map/practices.md)。类型设计路由策划，不进入空轴。随后只打开
一到两个匹配 leaf。只有 leaf 直接链接时，才读取脚本、场景、模板或资产。

同一能力同时存在 canonical owner 和 `gd-agentic-*` imported leaf 时，默认选择前者；只有请求
命中更窄技术、精确旧名或 imported leaf 独有脚本时才选后者，不同时加载两份近义正文。
混合请求选择程序为 lead 时，把美术、音效或发布结果写成可解析 handoff。

实现 accepted 规则、记录 implementation reference，或发现代码改变玩法语义时，只读
[程序契约 preflight](map/contract.md) 定位相关项；不静默改写产品或策划意图。

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
