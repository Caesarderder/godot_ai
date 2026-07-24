---
name: godot-qa-release
description: Use for Godot code review, automated tests, playtest evidence, regression, compatibility or performance evidence, Web export/runtime diagnosis, release gates, or release decisions. Diagnose and hand fixes to the implementation owner rather than taking over feature implementation. Route through one knowledge-map axis and only the smallest relevant leaves.
---

# 测试发布

本岗位拥有：代码审查、测试、缺陷证据、回归、兼容性、性能证据、Web 构建与发布判定。

不负责：发现的实现问题回到对应程序、美术或音效 owner，玩法假设回到策划。

先读 [岗位地图](map/index.md)，只选择 [阶段](map/stages.md) 或 [实践](map/practices.md)。
类型与功能系统问题路由策划或程序，不进入空轴。随后只打开一到两个匹配 leaf。只有 leaf
直接链接时，才读取脚本、场景、模板或资产。

Web export/runtime、性能或兼容性诊断由本岗位收集证据并定位边界；实际修复 handoff 给对应
程序、美术或音效 owner。普通功能 bug 不因出现“测试”或“review”字样就变成发布任务。

里程碑或发布验收、契约 drift、implemented/verified 状态判断时，只读
[测试发布契约 preflight](map/contract.md) 的 acceptance criteria 与直接证据；没有运行证据
不得标记 verified。

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
