#!/usr/bin/env python3
"""Failing knowledge-map validator; standard library only."""

from __future__ import annotations

import datetime as dt
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
REQUIRED_FIELDS = {
    "km_id",
    "km_type",
    "domain",
    "status",
    "owner",
    "last_verified",
    "source_of_truth",
    "validated_by",
    "tags",
    "related",
}
LIST_FIELDS = {"source_of_truth", "validated_by", "tags", "related"}
KM_TYPES = {
    "map",
    "domain",
    "workflow",
    "invariant",
    "decision",
    "runbook",
    "quality",
    "reference",
    "memory",
}
STATUSES = {"active", "draft", "stale", "deprecated"}
DOMAINS = {
    "product",
    "code",
    "architecture",
    "workflow",
    "quality",
    "agent-memory",
    "cross-domain",
    "factory-cultivation",
    "hero-formation",
    "battle-progression",
    "equipment-economy",
    "camp-quests",
    "platform-persistence",
}
TAG_PREFIXES = {
    "domain",
    "workflow",
    "reference",
    "quality",
    "lint",
    "decision",
    "memory",
    "risk",
}
MINIMUM_FILES = {
    "docs/index.md",
    "docs/map/index.md",
    "docs/map/schema.md",
    "docs/map/workflows.md",
    "docs/map/domains.md",
    "docs/map/invariants.md",
    "docs/map/glossary.md",
    "docs/workflows/knowledge-query.md",
    "docs/workflows/code-locating.md",
    "docs/workflows/impact-map.md",
    "docs/workflows/code-writing-review.md",
    "docs/workflows/knowledge-map-maintenance.md",
    "docs/memory/index.md",
    "docs/quality/lint-rules.md",
    "docs/quality/stale-docs.md",
    "docs/runbooks/docs-lint.md",
    "docs/decisions/ADR-0001-knowledge-map-structure.md",
}
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
HEADING_RE = re.compile(r"^#{1,6}\s+(.+?)\s*$", re.MULTILINE)
KM_ID_RE = re.compile(r"^[a-z][a-z0-9-]*\.[a-z0-9][a-z0-9.-]*$")


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def error(errors: list[str], path: Path, message: str) -> None:
    errors.append(f"{rel(path)}: {message}")


def parse_frontmatter(path: Path, errors: list[str]) -> tuple[dict[str, object], str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        error(errors, path, "missing opening YAML frontmatter delimiter")
        return {}, text
    try:
        end = lines.index("---", 1)
    except ValueError:
        error(errors, path, "missing closing YAML frontmatter delimiter")
        return {}, text

    data: dict[str, object] = {}
    current_list: str | None = None
    for line_no, line in enumerate(lines[1:end], start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - "):
            if current_list is None:
                error(errors, path, f"line {line_no}: list item without list key")
                continue
            value = line[4:].strip()
            cast = data.get(current_list)
            if isinstance(cast, list):
                cast.append(value)
            continue
        match = re.match(r"^([a-z_]+):(?:\s*(.*))?$", line)
        if not match:
            error(errors, path, f"line {line_no}: unsupported YAML syntax")
            current_list = None
            continue
        key, value = match.group(1), (match.group(2) or "").strip()
        if key in data:
            error(errors, path, f"line {line_no}: duplicate field {key}")
        if value:
            data[key] = value.strip("\"'")
            current_list = None
        else:
            data[key] = []
            current_list = key
    body = "\n".join(lines[end + 1 :]) + "\n"
    return data, body


def slugify_heading(value: str) -> str:
    value = re.sub(r"[`*_~]", "", value.strip().lower())
    value = re.sub(r"[^\w\-\u4e00-\u9fff ]", "", value)
    return re.sub(r"\s+", "-", value)


def anchors(text: str) -> set[str]:
    return {slugify_heading(match.group(1)) for match in HEADING_RE.finditer(text)}


def resolve_link(source: Path, raw_target: str) -> tuple[Path | None, str | None]:
    target = raw_target.strip().strip("<>")
    if target.startswith(("http://", "https://", "mailto:", "#")):
        return None, None
    path_part, separator, anchor = target.partition("#")
    resolved = (source.parent / path_part).resolve() if path_part else source.resolve()
    return resolved, anchor if separator else None


def main() -> int:
    errors: list[str] = []
    if not DOCS.is_dir():
        print("docs lint: docs/ is missing", file=sys.stderr)
        return 1

    doc_paths = sorted(DOCS.rglob("*.md"))
    actual = {rel(path) for path in doc_paths}
    for missing in sorted(MINIMUM_FILES - actual):
        errors.append(f"{missing}: required minimum knowledge-map file is missing")

    nodes: dict[Path, tuple[dict[str, object], str]] = {}
    ids: dict[str, Path] = {}
    for path in doc_paths:
        data, body = parse_frontmatter(path, errors)
        nodes[path.resolve()] = (data, body)
        missing_fields = REQUIRED_FIELDS - set(data)
        for field in sorted(missing_fields):
            error(errors, path, f"missing required field {field}")
        for field in LIST_FIELDS:
            if field in data and not isinstance(data[field], list):
                error(errors, path, f"{field} must be a YAML list")

        km_id = data.get("km_id")
        if isinstance(km_id, str):
            if not KM_ID_RE.fullmatch(km_id):
                error(errors, path, f"invalid km_id {km_id!r}")
            km_type = data.get("km_type")
            if isinstance(km_type, str) and km_id.split(".", 1)[0] != km_type:
                error(errors, path, f"km_id prefix must match km_type: {km_id!r} vs {km_type!r}")
            if km_id in ids:
                error(errors, path, f"duplicate km_id {km_id!r}; first seen in {rel(ids[km_id])}")
            else:
                ids[km_id] = path
        if data.get("km_type") not in KM_TYPES:
            error(errors, path, f"invalid km_type {data.get('km_type')!r}")
        if data.get("status") not in STATUSES:
            error(errors, path, f"invalid status {data.get('status')!r}")
        if data.get("domain") not in DOMAINS:
            error(errors, path, f"unregistered domain {data.get('domain')!r}")
        try:
            dt.date.fromisoformat(str(data.get("last_verified")))
        except ValueError:
            error(errors, path, f"invalid last_verified {data.get('last_verified')!r}")

        for tag in data.get("tags", []) if isinstance(data.get("tags"), list) else []:
            if ":" not in tag or tag.split(":", 1)[0] not in TAG_PREFIXES:
                error(errors, path, f"invalid tag {tag!r}")
            if tag.startswith("domain:") and tag.split(":", 1)[1] not in DOMAINS:
                error(errors, path, f"tag references unregistered domain {tag!r}")

    markdown_link_count = 0
    for path, (data, body) in nodes.items():
        for related in data.get("related", []) if isinstance(data.get("related"), list) else []:
            if related not in ids:
                error(errors, path, f"related km_id {related!r} does not exist")
        for source in data.get("source_of_truth", []) if isinstance(data.get("source_of_truth"), list) else []:
            if source.startswith("command:"):
                continue
            source_path = (ROOT / source).resolve()
            if not source_path.exists():
                error(errors, path, f"source_of_truth path does not exist: {source}")

        for match in LINK_RE.finditer(body):
            markdown_link_count += 1
            label, raw_target = match.group(1), match.group(2)
            target_path, anchor = resolve_link(path, raw_target)
            if target_path is None:
                continue
            if not target_path.exists():
                error(errors, path, f"broken link {raw_target!r}")
                continue
            if label.startswith("CODE:") and not target_path.exists():
                error(errors, path, f"CODE target does not exist: {raw_target!r}")
            if label.startswith("KM:"):
                linked_id = label[3:]
                expected = ids.get(linked_id)
                if expected is None:
                    error(errors, path, f"KM label references unknown km_id {linked_id!r}")
                elif expected.resolve() != target_path.resolve():
                    error(errors, path, f"KM label {linked_id!r} points to {rel(target_path)}, expected {rel(expected)}")
            if label.startswith("CMD:"):
                if not anchor:
                    error(errors, path, f"CMD link requires an anchor: {raw_target!r}")
                else:
                    target_text = target_path.read_text(encoding="utf-8")
                    if anchor not in anchors(target_text):
                        error(errors, path, f"CMD anchor #{anchor} does not exist in {rel(target_path)}")

    if errors:
        print(f"docs lint: FAILED ({len(errors)} errors)", file=sys.stderr)
        for item in errors:
            print(f"- {item}", file=sys.stderr)
        return 1

    print(f"docs nodes: {len(doc_paths)}")
    print(f"unique km_id: {len(ids)}")
    print(f"markdown links: {markdown_link_count}")
    print("docs lint: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
