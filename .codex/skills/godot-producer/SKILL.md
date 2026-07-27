---
name: godot-producer
description: Use for Godot product direction, scope, milestones, risk, project contracts and drift resolution, first-playable or vertical-slice gates, and for starting a new game from a brief in a blank or near-blank project. Do not use for a concrete implementation, debug, asset, audio, test, Web build, or release task merely containing make, build, continue, or review. Route through one knowledge-map axis and only the smallest relevant leaves.
---

# 制作人

本岗位拥有：产品目标、范围、阶段门禁、风险与跨岗位交付。

不负责：玩法规则路由策划，代码实现路由程序，视听生产路由美术或音效，验收与发布路由测试发布。

## 新游戏入口

当用户用一句话要求“做一个游戏”，或当前是空白/近空白工程时，先走
`阶段 -> game-prototype`。这条路由不要求用户说出制作人、原型或任何 leaf 名。

在程序架构或内容生产开始前，制作人必须先记录当前里程碑的最小产品脊柱：

- 玩家幻想与本次要证明的独特承诺；
- 30 秒核心循环与至少一个有代价的选择；
- 题材如何变成规则，而不只是名称、颜色或外观；
- 一局的目标时长、教学、变化、升级、高潮与结算；
- 成功、失败、重开和促使玩家再来一局的差异；
- 当前明确不做的内容与需要试玩回答的问题。

不要把这变成强制创意访谈。只有缺失信息会改变游戏身份、产生外部成本或造成难以
逆转的范围承诺时，才问一个最小问题；其他情况声明安全假设并继续推进。

先读 [岗位地图](map/index.md)，只选择一个初始轴：[阶段](map/stages.md) 或
[实践](map/practices.md)，随后打开一到两个同轴 leaf。类型、系统问题直接 handoff 给拥有该结果
的岗位，不进入空轴或 legacy index。只有 leaf 直接链接时，才读取脚本、场景、模板或资产。

新项目/里程碑、实质范围或规则变化、跨岗位交接、文档与实现冲突、里程碑或发布验收，按需进入
`实践 -> game-project-contract`。孤立 bug、无语义变化的视觉微调或纯重构不启动完整契约治理。
一句话新游戏仍以 `阶段 -> game-prototype` 作为唯一初始轴；产品脊柱形成后，只有确实需要建立
项目 source of truth 或跨岗位交接时，才延迟进入 contract，不把两个轴并行预加载。

## 风险与工件升级

选 leaf 前只判断工程成熟度、请求结果、最高风险声明，以及工程是否已有连贯 owner/pattern；不要
把它变成问卷。先选一个 leaf，第二个只解决不同的阻塞风险。读完 leaf 的完整 `REFERENCE.md`
后，仅当用户要实现/修复/具体产出、直接工件命中最高风险、且工程没有同等强的已验证模式时，
才按“focused test/runnable demo → GDScript/scene/resource prototype → template/config →
conceptual reference”打开最多三个工件。若正文要求 adaptation 前审查 prototype，至少打开一个，
否则必须记录拒绝全部候选的具体兼容性或项目适配理由。

编辑前用一行记录 `adapt`（说明项目化改动）、`reject`（说明兼容性/ownership 理由）或
`guidance-only`（只采用约束）；读到索引不等于使用了示例。缓存本轮已读文件，不重复读取未变
内容；运行时只跟随 wrapper/current `content_home`。内部 `SKILL.md` 读取失败时回到 wrapper 和
已安装 `REFERENCE.md`，不重试猜测的 legacy 路径，也不批量打开整个 scripts bundle。

Do not load every axis, invent a mandatory production workflow, or treat preserved reference-only
material as approved for the Godot 4.6.x GDScript Web Compatibility single-thread target.
