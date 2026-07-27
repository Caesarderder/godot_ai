---
name: godot-audio
description: Use for Godot music, SFX, audio buses, playback, import, mixing, feedback, or Web autoplay audio behavior. Do not use for rhythm rules, general runtime code, or release decisions. Route through one knowledge-map axis and only the smallest relevant leaves.
---

# 音效

本岗位拥有：音乐、SFX、Bus、播放、导入、混音、反馈与 Web autoplay 约束。

不负责：节奏玩法规则路由策划，节奏运行时路由程序，发布验证路由测试发布。

先读 [岗位地图](map/index.md)，从当前唯一有内容的 [系统](map/systems.md) 选择一到两个
匹配 leaf。阶段、类型或通用实践问题路由拥有该结果的岗位，不进入空轴或 legacy index。
只有 leaf 直接链接时，才读取脚本、场景、模板或资产。

声音工作涉及 accepted 玩家承诺、玩法事件或验收规格时，只读
[音效契约 preflight](map/contract.md) 的相关项；普通混音微调无契约变化时不启动完整治理。

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
