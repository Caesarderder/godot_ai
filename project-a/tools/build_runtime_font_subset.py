#!/usr/bin/env python3
"""Build a deterministic runtime-only OTF subset from player-shipped text.

This tool intentionally requires an explicit output path and never overwrites the
upstream font. Install the official ``fonttools`` package in an isolated
environment before using ``--output``. ``--inspect`` needs only Python's standard
library and is safe to run in source verification.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import sys
import tempfile


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = PROJECT_ROOT / "assets/fonts/NotoSansCJKsc-Regular.otf"
RUNTIME_ROOTS = (
    PROJECT_ROOT / "game",
    PROJECT_ROOT / "scenes",
)
RUNTIME_FILES = (
    PROJECT_ROOT / "project.godot",
    PROJECT_ROOT / "scripts/slg_main.gd",
)
TEXT_EXTENSIONS = frozenset({".gd", ".godot", ".json", ".cfg", ".tscn", ".tres"})
MIN_NON_ASCII = 500
MAX_NON_ASCII = 2000


def runtime_text_files() -> list[Path]:
    files = list(RUNTIME_FILES)
    for root in RUNTIME_ROOTS:
        files.extend(
            path
            for path in root.rglob("*")
            if path.is_file() and path.suffix.lower() in TEXT_EXTENSIONS
        )
    return sorted(set(files))


def collect_codepoints() -> set[int]:
    codepoints = set(range(32, 127))
    for path in runtime_text_files():
        if not path.is_file():
            raise FileNotFoundError(f"runtime text source missing: {path}")
        codepoints.update(
            ord(character)
            for character in path.read_text(encoding="utf-8")
            if ord(character) >= 32
        )
    non_ascii = sum(codepoint > 127 for codepoint in codepoints)
    if not MIN_NON_ASCII <= non_ascii <= MAX_NON_ASCII:
        raise ValueError(
            "runtime text scope drifted outside the reviewed range: "
            f"{non_ascii} non-ASCII codepoints"
        )
    return codepoints


def codepoint_digest(codepoints: set[int]) -> str:
    payload = ",".join(f"{codepoint:04X}" for codepoint in sorted(codepoints))
    return hashlib.sha256(payload.encode("ascii")).hexdigest()


def file_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_subset(source: Path, output: Path, codepoints: set[int]) -> None:
    try:
        from fontTools import subset
        from fontTools.ttLib import TTFont
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "fontTools is required for subsetting. Install the official fonttools "
            "package in an isolated environment after approval."
        ) from exc

    source = source.resolve()
    output = output.resolve()
    if source == output:
        raise ValueError("refusing to overwrite the upstream font; choose a distinct --output")
    if not source.is_file():
        raise FileNotFoundError(f"font source missing: {source}")
    output.parent.mkdir(parents=True, exist_ok=True)

    options = subset.Options()
    options.canonical_order = True
    options.recalc_timestamp = False
    options.recommended_glyphs = True
    options.notdef_glyph = True
    options.notdef_outline = True
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]

    font = TTFont(source, recalcTimestamp=False)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=codepoints)
    subsetter.subset(font)

    with tempfile.NamedTemporaryFile(
        prefix=f".{output.name}.",
        suffix=".tmp",
        dir=output.parent,
        delete=False,
    ) as temporary:
        temporary_path = Path(temporary.name)
    try:
        font.save(temporary_path, reorderTables=False)
        temporary_path.replace(output)
    finally:
        temporary_path.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path)
    parser.add_argument(
        "--inspect",
        action="store_true",
        help="print the deterministic runtime character inventory without writing a font",
    )
    arguments = parser.parse_args()

    codepoints = collect_codepoints()
    non_ascii = sum(codepoint > 127 for codepoint in codepoints)
    print(
        "RUNTIME_FONT_CODEPOINTS: "
        f"{len(codepoints)} total, {non_ascii} non-ASCII, "
        f"sha256={codepoint_digest(codepoints)}"
    )
    if arguments.inspect:
        return 0
    if arguments.output is None:
        parser.error("--output is required unless --inspect is used")

    build_subset(arguments.source, arguments.output, codepoints)
    print(
        "RUNTIME_FONT_SUBSET_READY: "
        f"{arguments.output.resolve()} "
        f"bytes={arguments.output.stat().st_size} "
        f"sha256={file_digest(arguments.output.resolve())}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, RuntimeError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
