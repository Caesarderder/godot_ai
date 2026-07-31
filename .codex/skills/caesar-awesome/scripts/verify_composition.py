#!/usr/bin/env python3
"""Verify Caesar Awesome as one flat, self-contained skill package."""

from __future__ import annotations

import re
import sys
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parents[1]
SKILL = SKILL_DIR / "SKILL.md"
REPOSITORY = Path.cwd().resolve()
REQUIRED_FILES = (
    "commands/docs-init.md",
    "commands/docs-update.md",
    "commands/docs-review.md",
    "references/docs-discovery.md",
    "references/workbench-and-knowledge-map.md",
    "references/human-validation.md",
    "references/loop-guide.md",
    "references/test-scenario-authoring.md",
    "references/operating-contract.md",
    "references/explicit-commands.md",
    "references/managed-artifacts.md",
    "scripts/caesar_artifacts.py",
    "scripts/test_caesar_artifacts.py",
    "scripts/test_workbench_hq.py",
    "scripts/validate_loop_protocol.py",
    "scripts/validate_plan_paths.py",
    "scripts/workbench_hq.py",
    "schemas/run-spec.schema.json",
    "schemas/scenario.schema.json",
    "schemas/gate.schema.json",
    "schemas/evidence.schema.json",
    "schemas/finding.schema.json",
    "schemas/host-capabilities.schema.json",
    "schemas/progress.schema.json",
    "schemas/iteration-result.schema.json",
    "assets/templates/run-spec.json",
    "assets/templates/progress.json",
    "assets/workbench-template.html",
)
CONTRACT_MARKERS = {
    "references/docs-discovery.md": (
        "Docs Knowledge Map Pass",
        "Required decision schema fields",
        "USE_DOCS_ROUTE",
    ),
    "references/workbench-and-knowledge-map.md": (
        "强制 HQ 闭环",
        "Loop 状态接入",
        "loop-sync",
        "caesar-awesome:docs-init",
        "不得自动使用 `docs-init`",
        "validation-sync",
    ),
    "references/loop-guide.md": (
        "Test Scenario",
        "Integrate at declared checkpoints",
        "one-run",
        "Evidence and completion rules",
        "Only enter `completed`",
        "caesar-awesome:loop",
        "dormant unless",
    ),
    "references/test-scenario-authoring.md": (
        "Focused fixture first",
        "One-run coverage matrix",
        "dedicated_test_scene",
        "single_run_matrix",
    ),
}
MARKDOWN_TO_CHECK = (
    "SKILL.md",
    "commands/docs-init.md",
    "commands/docs-update.md",
    "commands/docs-review.md",
    "references/docs-discovery.md",
    "references/workbench-and-knowledge-map.md",
    "references/human-validation.md",
    "references/loop-guide.md",
    "references/test-scenario-authoring.md",
    "references/operating-contract.md",
    "references/explicit-commands.md",
    "references/managed-artifacts.md",
)


def frontmatter_name(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^name:\s*([a-z0-9-]+)\s*$", text, re.MULTILINE)
    if not match:
        raise RuntimeError(f"missing valid name frontmatter: {path}")
    return match.group(1)


def broken_markdown_links(path: Path) -> list[str]:
    links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", path.read_text(encoding="utf-8"))
    broken: list[str] = []
    for target in links:
        if target.startswith(("http://", "https://", "#")):
            continue
        relative = target.split("#", 1)[0]
        if relative and not (path.parent / relative).resolve().exists():
            broken.append(target)
    return broken


def main() -> int:
    errors: list[str] = []
    if not SKILL.is_file():
        errors.append(f"missing {SKILL}")
        skill_text = ""
    else:
        skill_text = SKILL.read_text(encoding="utf-8")
        if frontmatter_name(SKILL) != "caesar-awesome":
            errors.append("frontmatter name mismatch")
        for marker in (
            "caesar-awesome:docs-init",
            "$caesar-awesome docs-init",
            "caesar-awesome:loop",
            "$caesar-awesome loop",
            "Never infer",
        ):
            if marker not in skill_text:
                errors.append(f"explicit command contract is missing: {marker}")

    if (SKILL_DIR / "modules").exists():
        errors.append("flat package must not contain a modules directory")

    if (SKILL_DIR / "assets" / "workbench-hq.html").exists():
        errors.append("project-generated HQ HTML must not live inside the skill")

    for relative in REQUIRED_FILES:
        path = SKILL_DIR / relative
        if not path.is_file():
            errors.append(f"missing required flat resource: {relative}")

    retired_sibling_names = ("docs-hunter", "caesar-docs", "caesar-loop")
    for name in retired_sibling_names:
        if (SKILL_DIR.parent / name).exists():
            errors.append(f"retired Caesar sibling remains installed: {name}")

    for relative, markers in CONTRACT_MARKERS.items():
        path = SKILL_DIR / relative
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in text:
                errors.append(f"{relative} is missing contract marker: {marker}")

    forbidden = ("modules/", "MODULE.md")
    for relative in MARKDOWN_TO_CHECK:
        path = SKILL_DIR / relative
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for token in forbidden:
            if token in text:
                errors.append(f"{relative} retains obsolete structure token: {token}")
        broken = broken_markdown_links(path)
        if broken:
            errors.append(f"broken links in {relative}: {broken}")

    expected_install = REPOSITORY / ".codex" / "skills" / "caesar-awesome"
    if expected_install.resolve() == SKILL_DIR.resolve():
        repo_entry = REPOSITORY / "README.md"
        if repo_entry.is_file() and "caesar-docs:" in repo_entry.read_text(encoding="utf-8"):
            errors.append("README.md retains a retired Caesar command")
        loop_index = REPOSITORY / "docs" / "workbench" / "loops" / "index.md"
        if loop_index.is_file():
            index_text = loop_index.read_text(encoding="utf-8")
            if "assets/templates" in index_text or "example_gameplay_readability" in index_text:
                errors.append("Workbench run index treats package templates as an active run")
        hq = REPOSITORY / "docs" / "workbench" / "hq.md"
        if hq.is_file() and re.search(
            r"```loop[\s\S]*?run_dir:\s*\.codex/skills/caesar-awesome/assets/templates",
            hq.read_text(encoding="utf-8"),
        ):
            errors.append("HQ treats package templates as an active run")

    if errors:
        for error in errors:
            print(f"ERROR {error}", file=sys.stderr)
        return 1
    print("Caesar Awesome flat package: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
