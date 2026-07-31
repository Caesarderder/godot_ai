# Workbench 与知识地图控制

用于所有非平凡仓库任务的任务前后控制，以及初始化、更新或审查仓库知识地图。完全离线维护
本地 Caesar Workbench，不依赖官网、账号、API、网络或密钥。

## 强制 HQ 闭环

对每个非平凡仓库任务执行项目知识地图中的 Caesar Workbench（仓库内
`docs/workbench/`）：

1. **开始任务前**：读取最小知识地图链；执行 `python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py start --task "任务名"`。脚本零配置初始化 `docs/workbench/hq.md`，登记 `board #project`、`status #hq` 和 `chat #team`。
2. **执行期间**：出现新阻塞、范围变化或重要决定时，用 `note` 回写；不要等到最终总结才记录。
3. **结束任务前**：先同步受影响知识节点，再执行 `python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py finish --task "任务名" --summary "结果"`；脚本把卡片移到已完成、追加状态和聊天，并从 `docs/workbench/hq.md` 刷新 `docs/workbench/workbench-hq.html`。
4. HQ 是纯本地能力。不得访问 Workbench 官网或任何远端 API，不得要求账号、edit key、token 或网络。写入失败时明确报告，不能伪造成功。

一行修改、纯问答和用户明确要求跳过 HQ 时可跳过。任务开始/结束的 HQ 调用是仓库工作流，不替代代码验证和知识地图维护。

## Caesar Loop 状态接入

当任务显式启用 Loop 时，Loop JSON 是运行事实源，HQ 中的 `loop` 组件只是可重建投影：

1. 将一个 run 的 `run-spec.json`、`progress.json`、可选 `host-capabilities.json`，以及
   `evidence/`、`findings/`、`iterations/` 放在同一仓库内运行目录。
2. 场景合同、gate、finding、evidence、iteration 或状态发生实质变化后执行：

   ```bash
   python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py loop-sync \
     --run-dir "运行目录" --task "对应 HQ 任务名"
   ```

3. `loop-sync` 必须先通过 Caesar Loop 协议与实例校验，再更新
   `docs/workbench/loops/<run-id>.md` 知识节点、`docs/workbench/hq.md` 总览和 HTML；
   不得手工把投影改成与 JSON 不一致的状态。
4. HQ 任务卡仅附加 `loop` 与 `loop-state` 索引。是否完成仍由当前 integrated revision
   的质量门、证据新鲜度和未关闭 finding 决定，不能依据看板列或页面摘要推断。

## 浏览器真人验证

需要在浏览器内主持可用性测试、学习验证或观察任务时，读取
[human-validation.md](human-validation.md)，用 `validation-sync` 将仓库内 JSON spec
投影为 Workbench 交互面板。参与者答案、计时、误触、求助和阻碍可直接保存为仓库内
session JSON，也可从静态 HTML 导出。session 是待审查的原始观察记录，不会自动改变
Loop gate、finding 或 Evidence。

## 中文环境

默认使用中文执行本流程：

- 与用户沟通、审查结论、计划、发现和总结默认使用中文。
- 新增或更新的知识地图正文、标题、表格说明和运行手册说明默认使用中文。
- 保留机器可读标识的英文稳定性，包括 `caesar-awesome:*`、`km_id`、`km_type`、`domain`、`status`、`source_of_truth`、`validated_by`、`related`、目录名、文件名、代码符号、命令和链接标签。
- 如果现有节点正文是中文，沿用中文风格；如果需要保留英文术语，首次出现时给出中文语境或中文说明。
- 不把只存在于本地 skill、聊天上下文或隐藏记忆里的内容当作事实来源；长期事实必须写入 `docs/` 知识地图。

## 工作环境模型

把知识地图当成控制系统，而不是普通文档堆。

- **控制层**：入口、schema、工作流、不变量和任务路由。
- **前馈层**：领域边界、架构地图、文件归属和“先读什么”规则，用来在编辑前约束工作方向。
- **传感层**：lint 规则、链接检查、过期文档检测、测试和审查清单。
- **反馈层**：记忆、误判、经验、ADR 和 runbook，用来记录工作后发现的漂移。
- **执行层**：具体步骤、命令、脚本和验证流程。

知识地图必须让人和智能体使用同一批文件。不要依赖隐藏记忆、私有聊天上下文或只存在本地的 skill 作为事实来源。

## 命令路由

根据用户请求选择命令文档：

- `caesar-awesome:docs-init` / `$caesar-awesome docs-init`：读取 [docs-init](../commands/docs-init.md)，创建或规范化通用知识地图结构。只有该显式命令或用户明确要求初始化 Caesar 知识地图时才执行。
- 不得自动使用 `docs-init`；知识地图缺失只能触发报告和授权请求。
- 更新路线：读取 [docs-update](../commands/docs-update.md)，在代码、架构、工作流或归属变化后更新知识地图。
- 审查路线：读取 [docs-review](../commands/docs-review.md)，审查知识地图的正确性和可维护性。
- Workbench 路线：若项目有 `docs/workbench/index.md` 则先读取；没有时按本
  reference 的 HQ 合同初始化、维护或渲染知识地图内置的 Caesar Workbench。

如果用户没有显式给出模式，就按最安全的含义推断：审查/检查类请求使用 `review`，已有文档修改使用 `update`。仓库没有清晰地图时只报告缺失并做最小安全发现，不得自动使用 `init`。

## 结构定义

需要从零创建、规范化或判断知识地图结构时，按需读取这些 reference：

- [references/knowledge-map-structure.md](knowledge-map-structure.md)：目录结构、最小启动集、初始化策略。
- [references/directory-operations.md](directory-operations.md)：不同目录新增、修改、维护时的同步操作。
- [references/index-structure.md](index-structure.md)：公共入口、控制入口、工作流索引、领域索引和实现索引。
- [references/node-schema.md](node-schema.md)：节点 frontmatter、正文结构和结构枚举。
- [references/domain-tags.md](domain-tags.md)：`domain` 与 `tags` 的创建、管理、维护规则。
- [references/impact-map.md](impact-map.md)：impact map 的用途、生成时机、模板和写法。
- [references/link-validation.md](link-validation.md)：链接标签、事实优先级和验证规则。
- [references/repo-entry-sync.md](repo-entry-sync.md)：`AGENTS.md`、`ARCHITECTURE.md`、`README.md` 与 `docs/` 的同步规则。

## 共用发现规则

改文件前先检查本地仓库：

1. 读取仓库指导文件（如果存在）：`AGENTS.md`、`ARCHITECTURE.md`、`README.md`。
2. 用 `rg --files -g 'docs/**' -g '*ARCHITECTURE*' -g 'AGENTS.md'` 查找地图入口。
3. 优先使用仓库当前的地图入口，而不是过期说明。常见入口：
   - `docs/index.md`
   - `docs/map/index.md`
   - `docs/map/schema.md`
   - `docs/map/workflows.md`
4. 如果说明互相冲突，先报告冲突。文档结构以当前地图入口和 schema 为准；实现位置以文件归属和参考索引为准。

读到下一步已经明确时就停止，不要为了单个任务展开整棵文档树。

## 共用编辑规则

- 事实放在 `docs/`，不要只写在 skill 里。
- 索引保持短小并偏导航；详细事实放到 references。
- 优先更新已有节点，不要创建平行重复节点。
- 不要在多个文件里复制同一个事实来源；用链接指向它。
- 用 ADR 记录长期结构决策。
- 只有验证过、会改变未来智能体行为的反馈才写入 memory。
- 地图过渡期要显式标记旧路径为 deprecated 或 stale，不要静默混用新旧布局。
