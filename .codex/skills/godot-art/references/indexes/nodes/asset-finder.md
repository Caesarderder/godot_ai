---
km_id: reference.skill-art-system-asset-finder
km_type: reference
domain: game
status: active
last_verified: 2026-07-24
source_of_truth:
  - godot-art/references/systems/asset-finder/SKILL.md
validated_by:
  - manual-workflow-review
tags:
  - role:art
  - axis:system
axis: system
activation: contextual
canonical_role: art
public_skill: godot-art
canonical_technical_owner: asset-finder
source_skill: asset-finder
content_home: godot-art/references/systems/asset-finder/SKILL.md
compatibility: default
routes_to:
  - assets-pipeline
aliases:
  - asset-search
  - art-assets
  - free-game-assets
---

# asset-finder

## 目标

从已登记的美术素材网站查找满足需求、允许目标用途的素材，安全下载到当前 Godot
工程，并把来源、许可证和导入结果留在工程内。

## 什么时候读取

用户要求查找、挑选、下载或导入 2D、3D、UI、图标、贴图、动画或其他视觉素材时读取。
例如：“找一套免费的 2D 农场地图素材并放进这个工程”。

## 职责

- [读取完整工作流](../../systems/asset-finder/SKILL.md)
- 只从工作流的[素材源登记表](../../systems/asset-finder/references/sources.md)开始查找。
- 下载完成后，按 [assets-pipeline](assets-pipeline.md) 记录来源、许可证并验证 Godot 导入。

## 不负责什么

音乐和音效路由 `godot-audio`；程序化导入器、TileMap 运行时代码或资源加载代码路由
`godot-programming`。不要把“免费下载”自动解释为“允许商用”。

## 验证

确认地图入口可达、本地链接有效、下载文件来自登记域名、许可证证据已保存、工程原文件
未被静默覆盖，并检查 Godot 导入错误。
