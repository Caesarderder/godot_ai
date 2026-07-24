---
name: caesar-godot-skills
description: 将 Builda Agent 的 project-skills catalog 中全部普通 skills 合并迁移到当前 caesar Godot 工程。用户提到 caesar-godot-skills、要求迁移或同步 Builda project-skills、覆盖工程内同名 skill，或强调保留目标中旧有的其他 skills 时使用。
---

# Caesar Godot Skills

把以下来源中的每个直接子 skill 完整迁移到本工程：

`/Users/hortor/workspace2/builda/web_env/builda_agent/project-skills`

目标固定为本 skill 所在工程的 `.codex/skills/`。

## 执行

1. 先运行 dry-run，展示将新增和替换的 skill：

   ```bash
   python3 .codex/skills/caesar-godot-skills/scripts/migrate_skills.py --dry-run
   ```

2. 确认来源和目标路径与输出正确后，立即执行迁移：

   ```bash
   python3 .codex/skills/caesar-godot-skills/scripts/migrate_skills.py
   ```

3. 报告新增数、替换数和保留的目标独有 skill 数。

## 迁移契约

- 将来源目录下直接包含 `SKILL.md` 的子目录视为普通 skill，并复制整个目录，包括 `agents/`、`scripts/`、`references/`、`assets/` 和其他资源。
- 以 `builda_agent/project-skills/` 的当前目录内容为准，不从 Worker 生成的 `codex-home/skills/` 反向同步。
- 对同名目标 skill 做目录级替换，使其内容与来源一致。
- 不删除来源中不存在的任何目标 skill 或其他目标条目。
- 忽略 `.system` 等不直接包含 `SKILL.md` 的目录；不要把 Codex 内置系统目录当作普通项目 skill。
- 使用脚本的完整暂存和失败回滚，不要改写为裸 `cp`、`rm` 或带目标全局 `--delete` 的同步命令。
- 来源不存在、来源无有效 skill、目标不合法或复制失败时停止并报告；不要自行猜测其他来源或目标。
- 目标若存在同名但不含 `SKILL.md` 的条目，停止并报告冲突，不要覆盖非 skill 数据。
- 回滚可处理常规复制/切换错误和一次 `KeyboardInterrupt`；进程被强制终止或机器掉电时，报告遗留的 `.caesar-godot-skills-*` 恢复目录，不要声称全局原子性。
- 迁移使用 `.caesar-godot-skills.lock` 防止并发执行；锁或恢复目录异常遗留时先报告并人工核对，不要自动删除后重试。
