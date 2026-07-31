#!/usr/bin/env python3
"""Reject stale Caesar paths and commands in an agent plan or handoff."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


FORBIDDEN = {
    r"\bdocs-hunter\b": "retired capability name",
    r"\bcaesar-docs\b": "retired capability name",
    r"(?<![\w-])caesar-loop\b": "retired capability name",
    r"\.codex/skills/(?:docs-hunter|caesar-docs|caesar-loop)(?:/|\b)": "retired skill path",
    r"\.codex/skills/caesar-awesome/modules/": "retired nested layout",
    r"\bcaesar-docs:(?:init|update|review|hq)\b": "retired command",
    r"\bmodules/.+?/MODULE\.md\b": "retired module entry",
    r"\.codex/skills/caesar-awesome/assets/workbench-hq\.html": "project state inside skill assets",
    r"\bpython3 docs/workbench/workbench_hq\.py\b": "retired external Workbench writer",
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", help="Plan file; omit to read stdin.")
    args = parser.parse_args()
    text = Path(args.path).read_text(encoding="utf-8") if args.path else sys.stdin.read()
    errors: list[str] = []
    for pattern, label in FORBIDDEN.items():
        for match in re.finditer(pattern, text, re.IGNORECASE):
            line = text.count("\n", 0, match.start()) + 1
            errors.append(f"line {line}: {label}: {match.group(0)}")
    if errors:
        for error in errors:
            print(f"ERROR {error}", file=sys.stderr)
        return 1
    print("Caesar plan paths: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
