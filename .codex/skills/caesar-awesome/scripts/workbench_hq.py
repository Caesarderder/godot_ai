#!/usr/bin/env python3
"""Maintain a dependency-free local Markdown HQ and render it as HTML."""

from __future__ import annotations

import argparse
import json
import re
import secrets
import subprocess
import sys
import webbrowser
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path.cwd().resolve()
SKILL_ROOT = Path(__file__).resolve().parents[1]
HQ_DIR = ROOT / "docs" / "workbench"
SOURCE = HQ_DIR / "hq.md"
OUTPUT = HQ_DIR / "workbench-hq.html"
TEMPLATE = SKILL_ROOT / "assets" / "workbench-template.html"
LOOP_VALIDATOR = SKILL_ROOT / "scripts" / "validate_loop_protocol.py"
LOOP_KNOWLEDGE_DIR = HQ_DIR / "loops"
HUMAN_VALIDATION_DIR = HQ_DIR / "human-validation"


def now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def local_date() -> str:
    return datetime.now().astimezone().date().isoformat()


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(content, encoding="utf-8")
    temporary.replace(path)


def initial_document(title: str, description: str = "") -> str:
    summary = description or "本地项目任务、状态与协作记录。"
    stamp = now()
    return f"""---
km_id: reference.workbench-hq-state
km_type: reference
domain: workflow
status: active
owner: maintainers
last_verified: {local_date()}
source_of_truth:
  - docs/workbench/hq.md
validated_by:
  - python3 tools/docs_lint.py
  - python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py render
tags:
  - workflow:task-control
related:
  - workflow.workbench-hq
---

# {title}

{summary}

```board #project
## 待办
## 进行中
## 已完成
```

```status #hq
state: building
- {stamp} 初始化本地 HQ
## Checklist
- [x] 初始化 board
- [x] 初始化 status
- [x] 初始化 chat
```

## 团队聊天

```chat #team
- {stamp} @caesar-awesome (agent): 本地 HQ 已就绪。
```
"""


def ensure_source(title: str | None = None, description: str = "") -> str:
    if not SOURCE.exists():
        project_title = title or f"{ROOT.name} 项目 HQ"
        atomic_write(SOURCE, initial_document(project_title, description))
    return SOURCE.read_text(encoding="utf-8")


def replace_fence(content: str, kind: str, fence_id: str, mutate) -> str:
    pattern = re.compile(
        rf"```{re.escape(kind)}(?:\s+#{re.escape(fence_id)})?\s*\n(.*?)\n```",
        re.DOTALL,
    )
    match = pattern.search(content)
    if not match:
        raise RuntimeError(f"缺少 ```{kind} #{fence_id} fence")
    body = mutate(match.group(1))
    return content[:match.start(1)] + body + content[match.end(1):]


def append_to_fence(content: str, kind: str, fence_id: str, line: str) -> str:
    return replace_fence(content, kind, fence_id, lambda body: body.rstrip() + "\n" + line)


def clean_projection(value: object) -> str:
    """Keep generated loop projection values single-line and fence-safe."""
    return str(value if value is not None else "").replace("|", "／").replace("\n", " ").strip()


def relative_repo_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(ROOT.resolve()).as_posix()
    except ValueError as exc:
        raise RuntimeError(f"Loop 文件必须位于仓库内：{path}") from exc


def load_json_object(path: Path, label: str) -> dict:
    if not path.is_file():
        raise RuntimeError(f"缺少 {label}：{path}")
    if path.stat().st_size > 2_000_000:
        raise RuntimeError(f"{label} 超过 2MB：{path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{label} 不是有效 JSON：{path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RuntimeError(f"{label} 根节点必须是 object：{path}")
    return value


def validate_human_validation_spec(value: dict) -> dict:
    require_fields(
        value,
        "Human Validation spec",
        (
            "validation_id",
            "title",
            "run_id",
            "gate_id",
            "participant_target",
            "pass_threshold",
            "instructions",
            "tasks",
        ),
    )
    validation_id = str(value["validation_id"])
    if not re.fullmatch(r"[A-Za-z0-9._-]{1,80}", validation_id):
        raise RuntimeError("validation_id 只能包含字母、数字、点、下划线和连字符")
    for field in ("title", "run_id", "gate_id"):
        if not isinstance(value[field], str) or not value[field].strip():
            raise RuntimeError(f"Human Validation spec 的 {field} 必须是非空字符串")
    target = value["participant_target"]
    threshold = value["pass_threshold"]
    if not isinstance(target, int) or target < 1 or target > 100:
        raise RuntimeError("participant_target 必须是 1–100 的整数")
    if not isinstance(threshold, int) or threshold < 1 or threshold > target:
        raise RuntimeError("pass_threshold 必须是 1–participant_target 的整数")
    instructions = value["instructions"]
    if not isinstance(instructions, list) or not instructions or not all(
        isinstance(item, str) and item.strip() for item in instructions
    ):
        raise RuntimeError("instructions 必须是非空字符串数组")
    tasks = value["tasks"]
    if not isinstance(tasks, list) or not tasks:
        raise RuntimeError("tasks 必须是非空数组")
    task_ids: set[str] = set()
    for index, task in enumerate(tasks):
        if not isinstance(task, dict):
            raise RuntimeError(f"tasks[{index}] 必须是 object")
        require_fields(task, f"tasks[{index}]", ("task_id", "title", "prompt", "dimensions"))
        task_id = str(task["task_id"])
        if not re.fullmatch(r"[A-Za-z0-9._-]{1,80}", task_id) or task_id in task_ids:
            raise RuntimeError(f"tasks[{index}].task_id 无效或重复")
        task_ids.add(task_id)
        if not isinstance(task["title"], str) or not task["title"].strip():
            raise RuntimeError(f"tasks[{index}].title 必须是非空字符串")
        if not isinstance(task["prompt"], str) or not task["prompt"].strip():
            raise RuntimeError(f"tasks[{index}].prompt 必须是非空字符串")
        dimensions = task["dimensions"]
        if (
            not isinstance(dimensions, list)
            or not dimensions
            or any(item not in ("goal", "risk", "action") for item in dimensions)
            or len(dimensions) != len(set(dimensions))
        ):
            raise RuntimeError(
                f"tasks[{index}].dimensions 只能包含不重复的 goal/risk/action"
            )
    normalized = json.loads(json.dumps(value, ensure_ascii=False))
    normalized["schema_version"] = "caesar-human-validation/v1"
    return normalized


def human_validation_fence(spec: dict) -> str:
    validation_id = spec["validation_id"]
    body = json.dumps(spec, ensure_ascii=False, indent=2, sort_keys=True)
    return f"```validation #{validation_id}\n{body}\n```"


def upsert_human_validation_fence(content: str, spec: dict) -> str:
    validation_id = spec["validation_id"]
    pattern = re.compile(
        rf"```validation\s+#{re.escape(validation_id)}\s*\n[\s\S]*?\n```",
        re.DOTALL,
    )
    fence = human_validation_fence(spec)
    if pattern.search(content):
        return pattern.sub(lambda _match: fence, content, count=1)
    marker = re.search(r"```status(?:\s+#hq)?\s*\n", content)
    if not marker:
        raise RuntimeError("缺少 status #hq，无法插入 Human Validation 面板")
    heading = "## Human Validation\n\n" if "## Human Validation" not in content else ""
    return content[:marker.start()] + heading + fence + "\n\n" + content[marker.start():]


def human_validation_specs(content: str) -> dict[str, dict]:
    specs: dict[str, dict] = {}
    for match in re.finditer(
        r"```validation\s+#([A-Za-z0-9._-]+)\s*\n([\s\S]*?)\n```",
        content,
    ):
        try:
            raw = json.loads(match.group(2))
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"validation #{match.group(1)} 不是有效 JSON：{exc}") from exc
        spec = validate_human_validation_spec(raw)
        if spec["validation_id"] != match.group(1):
            raise RuntimeError("validation fence ID 必须与 spec.validation_id 一致")
        specs[spec["validation_id"]] = spec
    return specs


def validate_human_validation_session(payload: dict, spec: dict) -> dict:
    require_fields(
        payload,
        "Human Validation session",
        ("validation_id", "participant_id", "device", "browser", "task_results"),
    )
    if payload["validation_id"] != spec["validation_id"]:
        raise RuntimeError("session.validation_id 与验证流程不一致")
    participant_id = str(payload["participant_id"]).strip()
    if not re.fullmatch(r"[A-Za-z0-9._-]{1,64}", participant_id):
        raise RuntimeError("participant_id 只能使用 1–64 位匿名字母数字标识")
    for field in ("device", "browser"):
        if not isinstance(payload[field], str) or not payload[field].strip():
            raise RuntimeError(f"session.{field} 必须是非空字符串")
    results = payload["task_results"]
    expected_ids = [task["task_id"] for task in spec["tasks"]]
    if not isinstance(results, list) or [item.get("task_id") for item in results] != expected_ids:
        raise RuntimeError("task_results 必须按 spec.tasks 顺序完整提交")
    for result, task in zip(results, spec["tasks"]):
        if not isinstance(result, dict):
            raise RuntimeError("task_results 条目必须是 object")
        answers = result.get("answers", {})
        timings = result.get("timings_seconds", {})
        if not isinstance(answers, dict) or not isinstance(timings, dict):
            raise RuntimeError("answers 与 timings_seconds 必须是 object")
        for dimension in task["dimensions"]:
            answer = answers.get(dimension)
            timing = timings.get(dimension)
            if not isinstance(answer, str) or not answer.strip():
                raise RuntimeError(f"{task['task_id']}.{dimension} 缺少口头答案")
            if not isinstance(timing, (int, float)) or timing < 0 or timing > 3600:
                raise RuntimeError(f"{task['task_id']}.{dimension} 计时无效")
        wrong_taps = result.get("wrong_taps", 0)
        if not isinstance(wrong_taps, int) or wrong_taps < 0 or wrong_taps > 999:
            raise RuntimeError(f"{task['task_id']}.wrong_taps 无效")
        if not isinstance(result.get("needed_help", False), bool):
            raise RuntimeError(f"{task['task_id']}.needed_help 必须是 boolean")
        if not isinstance(result.get("obstruction", ""), str):
            raise RuntimeError(f"{task['task_id']}.obstruction 必须是字符串")
    normalized = json.loads(json.dumps(payload, ensure_ascii=False))
    normalized["schema_version"] = "caesar-human-validation-session/v1"
    normalized["recorded_at"] = now()
    return normalized


def save_human_validation_session(payload: dict, spec: dict) -> Path:
    session = validate_human_validation_session(payload, spec)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    suffix = secrets.token_hex(3)
    path = (
        HUMAN_VALIDATION_DIR
        / spec["validation_id"]
        / "sessions"
        / f"{stamp}-{session['participant_id']}-{suffix}.json"
    )
    atomic_write(path, json.dumps(session, ensure_ascii=False, indent=2) + "\n")
    return path


def human_validation_session_summaries(validation_id: str) -> list[dict]:
    if not re.fullmatch(r"[A-Za-z0-9._-]{1,80}", validation_id):
        raise RuntimeError("validation_id 无效")
    directory = HUMAN_VALIDATION_DIR / validation_id / "sessions"
    summaries: list[dict] = []
    for path in sorted(directory.glob("*.json")) if directory.is_dir() else []:
        value = load_json_object(path, "Human Validation session")
        timings = [
            float(timing)
            for result in value.get("task_results", [])
            if isinstance(result, dict)
            for timing in (
                result.get("timings_seconds", {}).values()
                if isinstance(result.get("timings_seconds"), dict)
                else []
            )
            if isinstance(timing, (int, float))
        ]
        summaries.append(
            {
                "participant_id": value.get("participant_id", ""),
                "recorded_at": value.get("recorded_at", ""),
                "device": value.get("device", ""),
                "browser": value.get("browser", ""),
                "passed_two_second": bool(timings) and all(timing <= 2.0 for timing in timings),
                "path": relative_repo_path(path),
            }
        )
    return summaries


def loop_files(run_dir: Path) -> tuple[Path, Path, Path | None, list[Path], list[Path], list[Path]]:
    run_dir = run_dir.resolve()
    if not run_dir.is_dir():
        raise RuntimeError(f"Loop run 目录不存在：{run_dir}")
    try:
        run_dir.relative_to(ROOT.resolve())
    except ValueError as exc:
        raise RuntimeError(f"Loop run 目录必须位于仓库内：{run_dir}") from exc
    run_spec = run_dir / "run-spec.json"
    progress = run_dir / "progress.json"
    host = run_dir / "host-capabilities.json"
    return (
        run_spec,
        progress,
        host if host.is_file() else None,
        sorted((run_dir / "evidence").glob("*.json")),
        sorted((run_dir / "findings").glob("*.json")),
        sorted((run_dir / "iterations").glob("*.json")),
    )


def require_fields(value: dict, label: str, fields: tuple[str, ...]) -> None:
    missing = [field for field in fields if field not in value]
    if missing:
        raise RuntimeError(f"{label} 缺少字段：{', '.join(missing)}")


def loop_knowledge_path(run_id: str) -> Path:
    slug = re.sub(r"[^a-z0-9.-]+", "-", run_id.lower()).strip(".-")
    if not slug:
        raise RuntimeError("run_id 无法生成知识节点 slug")
    return LOOP_KNOWLEDGE_DIR / f"{slug}.md"


def loop_index_document() -> str:
    return f"""---
km_id: map.caesar-loop-runs
km_type: map
domain: workflow
status: active
owner: maintainers
last_verified: {local_date()}
source_of_truth:
  - docs/workbench/loops
validated_by:
  - command:python3 tools/docs_lint.py
  - command:python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py loop-sync --run-dir <run-dir>
tags:
  - workflow:agent-loop
  - quality:evidence-gate
related:
  - workflow.caesar-loop
  - workflow.workbench-hq
---

# Caesar Loop 运行索引

本页由 `loop-sync` 维护。先从运行节点读取玩家结果、Test Scenario 和门禁，再沿
`source_of_truth` 检查机器 JSON 与 ledger；不要从摘要推断完成。

<!-- loop-runs:start -->
| Run | 状态 | 知识节点 |
|---|---|---|
<!-- loop-runs:end -->
"""


def upsert_loop_index(run_id: str, loop_state: str, knowledge_path: Path) -> None:
    index_path = LOOP_KNOWLEDGE_DIR / "index.md"
    content = (
        index_path.read_text(encoding="utf-8")
        if index_path.is_file()
        else loop_index_document()
    )
    row = (
        f"| `{run_id}` | `{loop_state}` | "
        f"[KM:reference.caesar-loop-run-{knowledge_path.stem}]({knowledge_path.name}) |"
    )
    row_pattern = re.compile(rf"^\| `{re.escape(run_id)}` \|.*$", re.MULTILINE)
    if row_pattern.search(content):
        content = row_pattern.sub(lambda _match: row, content, count=1)
    else:
        marker = "<!-- loop-runs:end -->"
        if marker not in content:
            raise RuntimeError("Caesar Loop 运行索引缺少生成区标记")
        content = content.replace(marker, row + "\n" + marker, 1)
    content = re.sub(
        r"^(last_verified:\s*)\d{4}-\d{2}-\d{2}",
        rf"\g<1>{local_date()}",
        content,
        count=1,
        flags=re.MULTILINE,
    )
    atomic_write(index_path, content)


def loop_knowledge_node(run_id: str, loop_state: str, run_dir: Path, body: str) -> tuple[Path, str]:
    path = loop_knowledge_path(run_id)
    run_path = relative_repo_path(run_dir)
    content = f"""---
km_id: reference.caesar-loop-run-{path.stem}
km_type: reference
domain: workflow
status: active
owner: maintainers
last_verified: {local_date()}
source_of_truth:
  - {run_path}
validated_by:
  - command:python3 .codex/skills/caesar-awesome/scripts/validate_loop_protocol.py --run-dir {run_path}
  - command:python3 .codex/skills/caesar-awesome/scripts/workbench_hq.py loop-sync --run-dir {run_path}
tags:
  - workflow:agent-loop
  - quality:evidence-gate
related:
  - map.caesar-loop-runs
  - workflow.caesar-loop
  - workflow.workbench-hq
---

# Caesar Loop Run：{run_id}

本节点由 `loop-sync` 从运行 JSON 与 ledger 生成，记录当前 `{loop_state}` 状态。原始
`RunSpec`、`Progress`、`EvidenceRecord`、`Finding` 与 `IterationResult` 是事实源；
不要手工修改本页来关闭质量门。评审应先进入子任务绑定的 Test Scenario，再检查当前
revision 的证据。全部运行见 [KM:map.caesar-loop-runs](index.md)。

```loop #{run_id}
{body}
```
"""
    return path, content


def loop_projection(run_dir: Path) -> tuple[str, str, str]:
    if not LOOP_VALIDATOR.is_file():
        raise RuntimeError(f"缺少 Caesar Loop validator：{LOOP_VALIDATOR}")
    validation = subprocess.run(
        [sys.executable, str(LOOP_VALIDATOR), "--run-dir", str(run_dir)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if validation.returncode != 0:
        detail = (validation.stderr or validation.stdout).strip()
        raise RuntimeError(f"Caesar Loop run 验证失败：{detail}")
    run_spec_path, progress_path, host_path, evidence_paths, finding_paths, iteration_paths = (
        loop_files(run_dir)
    )
    run_spec = load_json_object(run_spec_path, "RunSpec")
    progress = load_json_object(progress_path, "Progress")
    require_fields(
        run_spec,
        "RunSpec",
        ("schema_version", "run_id", "goal", "player_outcome", "scenarios", "quality_gates", "budgets"),
    )
    require_fields(
        progress,
        "Progress",
        ("schema_version", "run_id", "state", "revision", "iteration", "gate_status"),
    )
    run_id = clean_projection(run_spec["run_id"])
    if not run_id or progress["run_id"] != run_spec["run_id"]:
        raise RuntimeError("RunSpec 与 Progress 的 run_id 不一致")
    if run_spec["schema_version"] != "caesar-loop/v2" or progress["schema_version"] != "caesar-loop/v2":
        raise RuntimeError("Workbench 仅支持 caesar-loop/v2")
    if not isinstance(run_spec["scenarios"], list) or not isinstance(run_spec["quality_gates"], list):
        raise RuntimeError("RunSpec scenarios 与 quality_gates 必须是 array")
    if not isinstance(progress["gate_status"], dict):
        raise RuntimeError("Progress gate_status 必须是 object")

    evidence = [load_json_object(path, f"Evidence {path.name}") for path in evidence_paths]
    findings = [load_json_object(path, f"Finding {path.name}") for path in finding_paths]
    iterations = [load_json_object(path, f"Iteration {path.name}") for path in iteration_paths]
    for item in evidence + findings + iterations:
        if item.get("run_id") != run_spec["run_id"]:
            raise RuntimeError(f"Loop artifact run_id 不匹配：{item.get('run_id')}")
    host = load_json_object(host_path, "HostCapabilities") if host_path else None

    player = run_spec.get("player_outcome", {})
    if not isinstance(player, dict):
        raise RuntimeError("RunSpec player_outcome 必须是 object")
    budgets = run_spec.get("budgets", {})
    max_iterations = budgets.get("max_iterations", "?") if isinstance(budgets, dict) else "?"
    gate_status = progress["gate_status"]
    current_evidence = [item for item in evidence if item.get("freshness") == "current"]
    open_findings = [
        item
        for item in findings
        if item.get("status") in ("open", "in_progress", "blocked")
    ]
    terminal = {
        "completed",
        "blocked",
        "human_required",
        "capability_unavailable",
        "budget_exhausted",
        "no_material_progress",
        "regression_limit",
        "user_stopped",
        "failed",
    }
    knowledge_path = loop_knowledge_path(run_id)
    lines = [
        f"title: {clean_projection(run_spec.get('goal', run_id))}",
        f"state: {clean_projection(progress['state'])}",
        f"phase: {clean_projection(progress['state'])}",
        f"iteration: {clean_projection(progress['iteration'])}/{clean_projection(max_iterations)}",
        f"revision: {clean_projection(progress['revision'])}",
        f"active_unit: {clean_projection(progress.get('active_work_unit') or '—')}",
        f"run_dir: {relative_repo_path(run_dir)}",
        f"run_spec: {relative_repo_path(run_spec_path)}",
        f"progress: {relative_repo_path(progress_path)}",
        f"knowledge_node: {relative_repo_path(knowledge_path)}",
        f"updated_at: {now()}",
        f"terminal: {'yes' if progress['state'] in terminal else 'no'}",
        "## Player Outcome",
        f"- target: {clean_projection(player.get('target_player', ''))}",
        f"- platform: {clean_projection(player.get('platform', ''))}",
        f"- outcome: {clean_projection(player.get('outcome', ''))}",
        "## Test Scenarios",
    ]
    scenario_ids: set[str] = set()
    for scenario in run_spec["scenarios"]:
        if not isinstance(scenario, dict):
            raise RuntimeError("RunSpec scenario 必须是 object")
        require_fields(
            scenario,
            "Scenario",
            ("scenario_id", "player_question", "fast_review_route", "strict_regression_route"),
        )
        scenario_id = clean_projection(scenario["scenario_id"])
        scenario_ids.add(scenario_id)
        fast = scenario.get("fast_review_route", {})
        strict = scenario.get("strict_regression_route", {})
        ready = bool(
            isinstance(fast, dict)
            and fast.get("command")
            and isinstance(strict, dict)
            and strict.get("command")
            and scenario.get("reset")
        )
        lines.append(
            f"- [{'ready' if ready else 'incomplete'}] {scenario_id}"
            f" :: {clean_projection(scenario['player_question'])}"
            f" :: fast={clean_projection(fast.get('command', '') if isinstance(fast, dict) else '')}"
            f" :: strict={clean_projection(strict.get('command', '') if isinstance(strict, dict) else '')}"
        )

    lines.append("## Quality Gates")
    gate_ids: set[str] = set()
    for gate in run_spec["quality_gates"]:
        if not isinstance(gate, dict):
            raise RuntimeError("RunSpec gate 必须是 object")
        require_fields(gate, "Gate", ("gate_id", "profile", "claim", "scenario_ids"))
        gate_id = clean_projection(gate["gate_id"])
        gate_ids.add(gate_id)
        unknown = {clean_projection(item) for item in gate["scenario_ids"]} - scenario_ids
        if unknown:
            raise RuntimeError(f"Gate {gate_id} 引用了未知 Scenario：{sorted(unknown)}")
        matching = [item for item in current_evidence if item.get("gate_id") == gate["gate_id"]]
        status = clean_projection(gate_status.get(gate["gate_id"], "pending"))
        lines.append(
            f"- [{status}] {gate_id} :: {clean_projection(gate['profile'])}"
            f" :: {clean_projection(gate['claim'])} :: evidence={len(matching)}"
        )
    unknown_gate_state = set(map(str, gate_status)) - gate_ids
    if unknown_gate_state:
        raise RuntimeError(f"Progress 包含未知 Gate：{sorted(unknown_gate_state)}")

    lines.append("## Open Findings")
    if open_findings:
        for finding in open_findings:
            lines.append(
                f"- [{clean_projection(finding.get('status', 'open'))}]"
                f" {clean_projection(finding.get('finding_id', 'unknown'))}"
                f" :: {clean_projection(finding.get('severity', ''))}"
                f" :: {clean_projection(finding.get('player_impact', finding.get('observation', '')))}"
            )
    else:
        lines.append("- [clear] 无未关闭 finding")

    lines.append("## Evidence")
    if evidence:
        for item in evidence[-20:]:
            lines.append(
                f"- [{clean_projection(item.get('result', 'unknown'))}]"
                f" {clean_projection(item.get('evidence_id', 'unknown'))}"
                f" :: {clean_projection(item.get('evidence_type', ''))}"
                f" :: gate={clean_projection(item.get('gate_id', ''))}"
                f" :: freshness={clean_projection(item.get('freshness', ''))}"
                f" :: {clean_projection(item.get('artifact_or_command', ''))}"
            )
    else:
        lines.append("- [missing] 尚无 evidence")

    lines.append("## Host Capabilities")
    capabilities = host.get("capabilities", {}) if host else {}
    if isinstance(capabilities, dict) and capabilities:
        for name, capability in capabilities.items():
            value = capability if isinstance(capability, dict) else {}
            lines.append(
                f"- [{clean_projection(value.get('status', 'unknown'))}]"
                f" {clean_projection(name)} :: {clean_projection(value.get('evidence', ''))}"
            )
    else:
        lines.append("- [unknown] 未提供 HostCapabilities")

    lines.append("## Decisions")
    decisions = progress.get("decisions", [])
    if isinstance(decisions, list) and decisions:
        for decision in decisions[-8:]:
            if isinstance(decision, dict):
                lines.append(
                    f"- {clean_projection(decision.get('at', ''))}"
                    f" :: {clean_projection(decision.get('decision', ''))}"
                )
    else:
        lines.append("- — :: 尚无决策记录")
    lines.append(
        f"summary: scenarios={len(run_spec['scenarios'])}"
        f" gates={len(run_spec['quality_gates'])}"
        f" evidence={len(evidence)} current={len(current_evidence)}"
        f" findings={len(open_findings)} iterations={len(iterations)}"
    )
    return run_id, clean_projection(progress["state"]), "\n".join(lines)


def upsert_loop_fence(content: str, run_id: str, body: str) -> str:
    pattern = re.compile(
        rf"```loop\s+#{re.escape(run_id)}\s*\n[\s\S]*?\n```",
        re.DOTALL,
    )
    fence = f"```loop #{run_id}\n{body}\n```"
    if pattern.search(content):
        return pattern.sub(lambda _match: fence, content, count=1)
    marker = re.search(r"```status(?:\s+#hq)?\s*\n", content)
    if not marker:
        raise RuntimeError("缺少 status #hq，无法插入 Loop 面板")
    heading = "## Caesar Loop Runs\n\n"
    if "## Caesar Loop Runs" in content:
        heading = ""
    return content[:marker.start()] + heading + fence + "\n\n" + content[marker.start():]


def board_attach_loop(body: str, task: str, run_id: str, loop_state: str) -> str:
    card = re.compile(
        rf"^- \[(?P<mark>[ >x])\] {re.escape(task)}(?P<meta>[^\n]*)"
        rf"(?P<details>(?:\n(?:  |\t)[^\n]*)*)",
        re.MULTILINE,
    )
    match = card.search(body)
    if not match:
        raise RuntimeError(f"board 中找不到 Loop 关联任务：{task}")
    details = [
        line
        for line in match.group("details").splitlines()
        if line.strip()
        and not re.match(r"^(loop|loop-state):\s*", line.strip(), re.IGNORECASE)
    ]
    details.extend((f"  loop: {run_id}", f"  loop-state: {loop_state}"))
    replacement = (
        f"- [{match.group('mark')}] {task}{match.group('meta')}"
        + ("\n" + "\n".join(details) if details else "")
    )
    return body[:match.start()] + replacement + body[match.end():]


def board_start(body: str, task: str, tags: list[str]) -> str:
    if re.search(rf"^- \[[ >x]\] {re.escape(task)}(?:\s|$)", body, re.MULTILINE):
        return body
    card = f"- [>] {task}" + "".join(f" #{tag}" for tag in tags if tag)
    heading = re.search(r"^## 进行中\s*$", body, re.MULTILINE)
    if not heading:
        raise RuntimeError("board 缺少“## 进行中”列")
    return body[:heading.end()] + "\n" + card + body[heading.end():]


def board_finish(body: str, task: str, summary: str) -> str:
    card = re.compile(
        rf"^- \[[ >]\] {re.escape(task)}(?P<meta>[^\n]*)"
        rf"(?P<details>(?:\n(?:  |\t)[^\n]*)*)",
        re.MULTILINE,
    )
    match = card.search(body)
    meta = match.group("meta") if match else ""
    if match:
        body = body[:match.start()] + body[match.end():]
    heading = re.search(r"^## 已完成\s*$", body, re.MULTILINE)
    if not heading:
        raise RuntimeError("board 缺少“## 已完成”列")
    completed = f"\n- [x] {task}{meta}\n  {summary}"
    return body[:heading.end()] + completed + body[heading.end():]


def status_update(body: str, state: str | None, message: str) -> str:
    if state:
        if re.search(r"^state:\s*\S+", body, re.MULTILINE):
            body = re.sub(r"^state:\s*\S+", f"state: {state}", body, count=1, flags=re.MULTILINE)
        else:
            body = f"state: {state}\n" + body
    entry = f"- {now()} {message}"
    checklist = re.search(r"^## Checklist\s*$", body, re.MULTILINE)
    if checklist:
        return body[:checklist.start()].rstrip() + "\n" + entry + "\n" + body[checklist.start():]
    return body.rstrip() + "\n" + entry


def render() -> Path:
    content = ensure_source()
    html = TEMPLATE.read_text(encoding="utf-8")
    payload = json.dumps(content, ensure_ascii=False)
    html = html.replace("const EMBEDDED_MD = null;", f"const EMBEDDED_MD = {payload};")
    atomic_write(OUTPUT, html)
    return OUTPUT


def save(content: str) -> None:
    content = re.sub(
        r"^(last_verified:\s*)\d{4}-\d{2}-\d{2}",
        rf"\g<1>{local_date()}",
        content,
        count=1,
        flags=re.MULTILINE,
    )
    atomic_write(SOURCE, content.rstrip() + "\n")
    page = render()
    print(f"本地 HQ 已更新：{SOURCE}；页面：{page}")


def validate_hq(content: str) -> None:
    for kind, fence_id in (("board", "project"), ("status", "hq"), ("chat", "team")):
        pattern = rf"```{kind}(?:\s+#{fence_id})?\s*\n[\s\S]*?\n```"
        if not re.search(pattern, content):
            raise RuntimeError(f"保存被拒绝：缺少 {kind} #{fence_id}")
    if not content.startswith("---\n"):
        raise RuntimeError("保存被拒绝：知识地图 frontmatter 不可删除")
    loop_ids = re.findall(r"```loop\s+#([\w.-]+)\s*\n", content)
    if len(loop_ids) != len(set(loop_ids)):
        raise RuntimeError("保存被拒绝：Loop run_id 不可重复")
    validation_ids = re.findall(r"```validation\s+#([\w.-]+)\s*\n", content)
    if len(validation_ids) != len(set(validation_ids)):
        raise RuntimeError("保存被拒绝：Human Validation ID 不可重复")
    human_validation_specs(content)


def serve(port: int, open_browser: bool) -> None:
    ensure_source()
    render()
    token = secrets.token_urlsafe(24)

    class Handler(BaseHTTPRequestHandler):
        def allowed(self) -> bool:
            query = parse_qs(urlparse(self.path).query)
            return query.get("token", [""])[0] == token

        def send_bytes(self, status: int, body: bytes, content_type: str) -> None:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.wfile.write(body)

        def send_json(self, status: int, payload: dict) -> None:
            self.send_bytes(
                status,
                json.dumps(payload, ensure_ascii=False).encode("utf-8"),
                "application/json; charset=utf-8",
            )

        def do_GET(self) -> None:
            parsed = urlparse(self.path)
            if parsed.path == "/":
                self.send_bytes(
                    200, OUTPUT.read_bytes(), "text/html; charset=utf-8")
            elif parsed.path == "/api/hq" and self.allowed():
                self.send_json(200, {"content": SOURCE.read_text(encoding="utf-8")})
            elif parsed.path == "/api/validation-sessions" and self.allowed():
                try:
                    validation_id = parse_qs(parsed.query).get("validation_id", [""])[0]
                    self.send_json(
                        200,
                        {"sessions": human_validation_session_summaries(validation_id)},
                    )
                except (RuntimeError, OSError, json.JSONDecodeError) as exc:
                    self.send_json(400, {"error": str(exc)})
            else:
                self.send_json(404, {"error": "not found"})

        def do_PUT(self) -> None:
            parsed = urlparse(self.path)
            if parsed.path != "/api/hq" or not self.allowed():
                self.send_json(403, {"error": "forbidden"})
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
                if length <= 0 or length > 2_000_000:
                    raise RuntimeError("请求大小无效")
                payload = json.loads(self.rfile.read(length).decode("utf-8"))
                content = payload.get("content")
                if not isinstance(content, str):
                    raise RuntimeError("content 必须是字符串")
                validate_hq(content)
                save(content)
                self.send_json(200, {"ok": True, "content": SOURCE.read_text(encoding="utf-8")})
            except (RuntimeError, OSError, json.JSONDecodeError) as exc:
                self.send_json(400, {"error": str(exc)})

        def do_POST(self) -> None:
            parsed = urlparse(self.path)
            if parsed.path != "/api/validation-session" or not self.allowed():
                self.send_json(403, {"error": "forbidden"})
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
                if length <= 0 or length > 1_000_000:
                    raise RuntimeError("请求大小无效")
                payload = json.loads(self.rfile.read(length).decode("utf-8"))
                if not isinstance(payload, dict):
                    raise RuntimeError("session payload 必须是 object")
                specs = human_validation_specs(SOURCE.read_text(encoding="utf-8"))
                validation_id = str(payload.get("validation_id", ""))
                spec = specs.get(validation_id)
                if spec is None:
                    raise RuntimeError(f"找不到 Human Validation：{validation_id}")
                path = save_human_validation_session(payload, spec)
                self.send_json(
                    201,
                    {
                        "ok": True,
                        "path": relative_repo_path(path),
                        "sessions": human_validation_session_summaries(validation_id),
                    },
                )
            except (RuntimeError, OSError, json.JSONDecodeError) as exc:
                self.send_json(400, {"error": str(exc)})

        def log_message(self, fmt: str, *args) -> None:
            print(f"HQ {self.address_string()} - {fmt % args}")

    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    url = f"http://127.0.0.1:{server.server_port}/?token={token}"
    print(f"Caesar Workbench 编辑服务：{url}")
    print("按 Ctrl+C 停止；服务只监听本机。")
    if open_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nWorkbench 已停止。")
    finally:
        server.server_close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init")
    init.add_argument("--title")
    init.add_argument("--description", default="")
    init.add_argument("--force", action="store_true")
    sub.add_parser("render")
    server = sub.add_parser("serve")
    server.add_argument("--port", type=int, default=8765)
    server.add_argument("--no-open", action="store_true")
    start = sub.add_parser("start")
    start.add_argument("--task", required=True)
    start.add_argument("--tags", default="")
    note = sub.add_parser("note")
    note.add_argument("--message", required=True)
    note.add_argument("--state", choices=("building", "blocked", "awaiting-human", "done"))
    finish = sub.add_parser("finish")
    finish.add_argument("--task", required=True)
    finish.add_argument("--summary", required=True)
    finish.add_argument("--state", choices=("building", "blocked", "awaiting-human", "done"),
                        default="building")
    loop_sync = sub.add_parser("loop-sync")
    loop_sync.add_argument(
        "--run-dir",
        required=True,
        help="仓库内 Caesar Loop run 目录，包含 run-spec.json 与 progress.json",
    )
    loop_sync.add_argument(
        "--task",
        help="可选：把 run_id 和 loop-state 投影到同名 HQ 任务卡",
    )
    validation_sync = sub.add_parser("validation-sync")
    validation_sync.add_argument(
        "--input",
        required=True,
        help="仓库内 Human Validation spec JSON",
    )
    args = parser.parse_args()

    if args.command == "init":
        if SOURCE.exists() and not args.force:
            print(f"HQ 已存在：{SOURCE}")
        else:
            title = args.title or f"{ROOT.name} 项目 HQ"
            atomic_write(SOURCE, initial_document(title, args.description))
        print(render())
        return 0
    if args.command == "render":
        print(render())
        return 0
    if args.command == "serve":
        serve(args.port, not args.no_open)
        return 0

    content = ensure_source()
    if args.command == "start":
        tags = [item.strip().lstrip("#") for item in args.tags.split(",") if item.strip()]
        content = replace_fence(
            content, "board", "project", lambda body: board_start(body, args.task, tags))
        content = replace_fence(
            content, "status", "hq",
            lambda body: status_update(body, "building", f"开始：{args.task}"))
        content = append_to_fence(
            content, "chat", "team",
            f"- {now()} @caesar-awesome (agent): 开始任务：**{args.task}**。")
    elif args.command == "note":
        content = replace_fence(
            content, "status", "hq",
            lambda body: status_update(body, args.state, args.message))
        content = append_to_fence(
            content, "chat", "team",
            f"- {now()} @caesar-awesome (agent): {args.message}")
    elif args.command == "finish":
        content = replace_fence(
            content, "board", "project",
            lambda body: board_finish(body, args.task, args.summary))
        content = replace_fence(
            content, "status", "hq",
            lambda body: status_update(body, args.state, f"完成：{args.task} — {args.summary}"))
        content = append_to_fence(
            content, "chat", "team",
            f"- {now()} @caesar-awesome (agent): 完成任务：**{args.task}** — {args.summary}")
    elif args.command == "loop-sync":
        run_dir = Path(args.run_dir).resolve()
        run_id, loop_state, body = loop_projection(run_dir)
        knowledge_path, knowledge_content = loop_knowledge_node(
            run_id, loop_state, run_dir, body
        )
        content = upsert_loop_fence(content, run_id, body)
        if args.task:
            content = replace_fence(
                content,
                "board",
                "project",
                lambda current: board_attach_loop(
                    current, args.task, run_id, loop_state
                ),
            )
        hq_state = {
            "blocked": "blocked",
            "failed": "blocked",
            "regression_limit": "blocked",
            "capability_unavailable": "blocked",
            "human_required": "awaiting-human",
        }.get(loop_state, "building")
        content = replace_fence(
            content,
            "status",
            "hq",
            lambda current: status_update(
                current,
                hq_state,
                f"同步 Caesar Loop：{run_id} · {loop_state}",
            ),
        )
        atomic_write(knowledge_path, knowledge_content)
        upsert_loop_index(run_id, loop_state, knowledge_path)
    elif args.command == "validation-sync":
        input_path = Path(args.input).resolve()
        try:
            input_path.relative_to(ROOT)
        except ValueError as exc:
            raise RuntimeError("Human Validation spec 必须位于仓库内") from exc
        spec = validate_human_validation_spec(
            load_json_object(input_path, "Human Validation spec")
        )
        content = upsert_human_validation_fence(content, spec)
        content = replace_fence(
            content,
            "status",
            "hq",
            lambda current: status_update(
                current,
                "awaiting-human",
                f"同步 Human Validation：{spec['validation_id']}",
            ),
        )
    save(content)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, json.JSONDecodeError) as exc:
        print(f"错误：{exc}", file=sys.stderr)
        raise SystemExit(1)
