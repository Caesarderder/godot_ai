---
km_id: reference.skill-producer-stage-game-prototype
km_type: reference
domain: game
status: active
last_verified: 2026-07-24
source_of_truth:
  - legacy:project-skills/game-prototype
validated_by:
  - script:migrate-role-catalog
tags:
  - role:producer
  - axis:stage
axis: stage
activation: contextual
canonical_role: producer
public_skill: godot-producer
canonical_technical_owner: game-prototype
source_skill: game-prototype
content_home: godot-producer/references/stages/game-prototype/SKILL.md
compatibility: default
routes_to: []
aliases:
  - game-prototype
---

# game-prototype

## 目标

通过 制作人 岗位知识地图按需读取这项现有能力，不改写原始正文或工件。

## 什么时候读取

用户请求与 `game-prototype` 直接相关，且本节点是当前任务所需的一到两个最小叶子之一时。

## 职责

- [读取完整保留内容](../../stages/game-prototype/SKILL.md)
- 按保留内容中的直接链接继续读取脚本、场景、模板或资产。

保留正文中的 explicit-only 文案是历史源合同；当前是否发现本 leaf 以此 wrapper 的
`activation: contextual` 与 scope guard 为准，不能把源 frontmatter 当作平级可调用 Skill。

## 产品脊柱门禁

一句话新游戏请求先记录玩家承诺、30 秒循环与有代价的选择、题材如何改变规则、目标局长与
决策变化、成功/失败/重开/重玩理由、明确延期项和最高风险试玩问题。通用循环只换皮，或只增加
数量、血量、波次而不改变玩家决策，不能证明请求中的独特承诺。

## 不负责什么

不自动加载同轴其他节点，不复制其他岗位正文，不扩大默认兼容边界。

## 验证

迁移 manifest、catalog baseline 与目标文件 SHA-256 必须一致。
