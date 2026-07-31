---
km_id: reference.caesar-workbench
km_type: reference
domain: workflow
status: active
owner: maintainers
last_verified: 2026-07-30
source_of_truth:
  - docs/workbench/hq.md
  - .codex/skills/caesar-awesome/scripts/workbench_hq.py
  - .codex/skills/caesar-awesome/assets/workbench-template.html
validated_by:
  - python3 tools/docs_lint.py
  - python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py render
  - python3 .codex/skills/caesar-awesome/scripts/validate_loop_protocol.py
tags:
  - workflow:task-control
related:
  - workflow.workbench-hq
  - reference.workbench-hq-state
---

# Caesar Workbench 本地 HQ

## 契约

Caesar Workbench 是 `caesar-awesome` 自带的纯本地 Markdown 任务控制层，与任何同名网站或服务无关：

- `docs/workbench/hq.md`：知识地图中的唯一 HQ 状态源。
- `docs/workbench/workbench-hq.html`：由 Markdown 生成的项目自包含只读页面。
- `.codex/skills/caesar-awesome/scripts/workbench_hq.py`：唯一结构化写入口。
- `.codex/skills/caesar-awesome/assets/workbench-template.html`：Skill 内的离线渲染模板。

不使用账号、API、MCP、token、edit key、网络请求或后台服务。

## 可编辑看板

启动只监听本机的编辑服务：

```bash
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py serve
```

浏览器会打开带本次会话随机 token 的本地地址。可以新增、编辑、删除任务，并设置：

- 状态：待办、进行中、已完成；
- 负责人；
- 标签；
- 优先级：P0–P3；
- 截止日期；
- 描述。

保存会原子写回 `docs/workbench/hq.md` 并重新生成 HTML。服务仅绑定 `127.0.0.1`；关闭终端或按 `Ctrl+C` 即停止。直接双击 HTML 时为只读模式。

## Markdown 组件协议

- `board #project`：`##` 表示列；`- [ ]`、`- [>]`、`- [x]` 分别表示待办、进行中和完成。
- `status #hq`：`state:` 为总体状态，时间行记录工作日志，Checklist 记录长期门禁。
- `chat #team`：每行 `- <ISO> @name (agent): text` 表示协作消息。
- `loop #run_id`：展示 Caesar Loop 的玩家结果、Test Scenario、分门质量门、finding、
  evidence、host capability 与决策；内容由运行 JSON 自动投影，不手工维护。
- `validation #validation_id`：展示浏览器真人验证的任务、计时与记录表单；由仓库内 JSON
  spec 通过 `validation-sync` 投影，不在 Markdown 中手工拼表单。

协议属于本 skill 的本地格式。渲染器只解析并转义文本，不执行 Markdown 中的 HTML 或脚本。

## Caesar Loop 联动

一个 run 使用仓库内目录保存 `run-spec.json`、`progress.json`、可选
`host-capabilities.json`，以及 `evidence/`、`findings/`、`iterations/`。在场景合同、
门禁、证据、finding、iteration、决策或状态变化后同步：

```bash
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py loop-sync \
  --run-dir "docs/workbench/loops/<run-id>" \
  --task "对应任务名"
```

同步链路为：

```text
Caesar Loop JSON（事实源）
  → 协议与交叉引用校验
  → docs/workbench/loops/<run-id>.md 知识节点
  → hq.md 的跨任务 loop 投影
  → 自包含 HTML 的 Loop Dashboard
```

生成的 run 节点是正式知识地图成员，保存运行合同、场景、门禁、finding、evidence、host
capability 和决策的当前可读视图，并通过 frontmatter 指向原始运行目录。`loop-sync` 还会更新
同名任务的 `loop`、`loop-state` 元数据，并按状态把活动卡标记为
进行中、等待人工或阻塞。它不会把任务自动标记完成；完成仍必须满足 Caesar Loop 对当前
集成 revision 的全部证据门禁。若页面与 JSON 不一致，应修复 JSON 或生成逻辑后重新同步，
不得直接编辑投影冒充运行状态。

## 任务生命周期

在任意仓库根运行，无需预先配置：

```bash
# 可选；start 也会自动初始化
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py init \
  --title "项目 HQ" --description "项目任务控制中心"

# 每个非平凡任务开始前
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py start \
  --task "实现存档迁移" --tags "p0,save"

# 重要决定、范围变化或阻塞
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py note \
  --message "确认 schema v9 需要兼容 v8"

# 每个非平凡任务结束前
python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py finish \
  --task "实现存档迁移" --summary "迁移与回归测试通过"
```

每个写命令都会原子更新 Markdown 并重新生成 HTML。`render` 可单独重建页面。`init --force` 会覆盖现有 HQ，只能在用户明确要求重置时使用。

## 行为规则

- 开始前登记，结束前回写；不要只在最终回复里描述。
- 重要进展用 `note`，避免把实现细节全部堆进聊天。
- 同名活动卡只保留一张；完成时移动到已完成列。
- HQ 记录活动，长期事实仍进入 `docs/` 知识地图。
- `docs/workbench/` 属于知识地图并随仓库共享；HTML 固定生成到 `docs/workbench/workbench-hq.html`。
- 本地写入失败时返回非零。不得声称已维护成功。

## 本地查看

直接打开 `docs/workbench/workbench-hq.html` 时，看板为只读，真人验证表单可操作并导出
JSON。需要写回看板或直接保存验证 session 时运行 `serve`；页面仍不需要外网，并支持看板
筛选、状态卡、聊天流和临时载入另一份本地 Markdown。
