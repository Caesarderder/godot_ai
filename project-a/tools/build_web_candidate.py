#!/usr/bin/env python3
"""Create a clean, reproducible Godot Web release candidate.

The export happens outside the Godot project so generated Web icons cannot be
re-imported as editor sidecars. Two independent exports must match before the
candidate replaces ``build/web``.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = PROJECT_ROOT.parent


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _manifest(directory: Path) -> dict[str, dict[str, int | str]]:
    return {
        path.relative_to(directory).as_posix(): {
            "bytes": path.stat().st_size,
            "sha256": _sha256(path),
        }
        for path in sorted(directory.rglob("*"))
        if path.is_file()
    }


def _normalize_service_worker(directory: Path) -> None:
    worker = directory / "index.service.worker.js"
    if not worker.exists():
        raise RuntimeError("PWA service worker is missing")
    payload = _manifest(directory)
    payload.pop(worker.name, None)
    payload_digest = hashlib.sha256(
        json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()[:24]
    source = worker.read_text(encoding="utf-8")
    normalized, replacements = re.subn(
        r"const CACHE_VERSION = '[^']+';",
        f"const CACHE_VERSION = 'sha256-{payload_digest}';",
        source,
        count=1,
    )
    if replacements != 1:
        raise RuntimeError("could not normalize PWA CACHE_VERSION")
    worker.write_text(normalized, encoding="utf-8")


def _run(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        check=False,
        capture_output=True,
        text=True,
    )


def _git_text(*args: str) -> str:
    result = _run(["git", *args], REPO_ROOT)
    if result.returncode != 0:
        raise RuntimeError((result.stderr or result.stdout).strip())
    return result.stdout.strip()


def _project_dirty() -> bool:
    tracked = _git_text("status", "--porcelain", "--untracked-files=all", "--", "project-a")
    return bool(tracked)


def _safe_output_path(raw_path: Path) -> Path:
    output = raw_path if raw_path.is_absolute() else PROJECT_ROOT / raw_path
    output = output.resolve()
    allowed_root = (PROJECT_ROOT / "build").resolve()
    if output == allowed_root or allowed_root not in output.parents:
        raise ValueError(f"output must be a child of {allowed_root}")
    return output


def _export(godot: str, directory: Path) -> dict[str, dict[str, int | str]]:
    directory.mkdir(parents=True, exist_ok=False)
    result = _run(
        [
            godot,
            "--headless",
            "--path",
            str(PROJECT_ROOT),
            "--export-release",
            "Web",
            str(directory / "index.html"),
        ],
        REPO_ROOT,
    )
    if result.returncode != 0:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        raise RuntimeError(f"Godot Web export failed with exit code {result.returncode}")
    _normalize_service_worker(directory)
    return _manifest(directory)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="build/web")
    parser.add_argument("--allow-dirty", action="store_true")
    args = parser.parse_args()

    output = _safe_output_path(Path(args.output))
    godot = shutil.which("godot")
    if not godot:
        raise RuntimeError("godot executable not found on PATH")

    dirty = _project_dirty()
    if dirty and not args.allow_dirty:
        raise RuntimeError("project-a has uncommitted changes; commit them before freezing a candidate")

    godot_version_result = _run([godot, "--version"], REPO_ROOT)
    godot_version = (godot_version_result.stdout or godot_version_result.stderr).strip()
    if godot_version_result.returncode != 0 or not godot_version.startswith("4.6.3."):
        raise RuntimeError(f"expected Godot 4.6.3, got: {godot_version}")

    with tempfile.TemporaryDirectory(prefix="godot-web-candidate-") as temporary:
        temp_root = Path(temporary)
        # Let Godot settle any pending import-cache metadata before measuring
        # reproducibility. The warm-up output is never promoted.
        _export(godot, temp_root / "warmup")
        first_dir = temp_root / "first"
        second_dir = temp_root / "second"
        first_manifest = _export(godot, first_dir)
        second_manifest = _export(godot, second_dir)
        if first_manifest != second_manifest:
            changed = sorted(
                name for name in set(first_manifest) | set(second_manifest)
                if first_manifest.get(name) != second_manifest.get(name)
            )
            raise RuntimeError(
                f"two clean exports differ; candidate is not reproducible: {changed}"
            )

        candidate = {
            "project": "project-a",
            "version": _git_text("show", "HEAD:project-a/project.godot").split(
                'config/version="', 1
            )[1].split('"', 1)[0],
            "revision": _git_text("rev-parse", "HEAD"),
            "project_dirty": dirty,
            "godot_version": godot_version,
            "preset": "Web",
            "web_threads": False,
            "reproducible": True,
            "artifact_manifest": first_manifest,
        }
        (first_dir / "release-candidate.json").write_text(
            json.dumps(candidate, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        if output.exists():
            shutil.rmtree(output)
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(first_dir, output)

    audit = _run(
        [
            sys.executable,
            str(PROJECT_ROOT / "tools" / "release_audit.py"),
            "--artifact-dir",
            str(output),
        ],
        REPO_ROOT,
    )
    sys.stdout.write(audit.stdout)
    sys.stderr.write(audit.stderr)
    if audit.returncode != 0:
        return audit.returncode
    print(f"CANDIDATE_READY: {output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError) as exc:
        print(f"CANDIDATE_BUILD_FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
