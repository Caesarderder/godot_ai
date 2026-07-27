#!/usr/bin/env python3
"""Freeze and locally rehearse a deterministic Project A Web rollback artifact."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import gzip
import hashlib
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import tarfile
import tempfile


PROJECT_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = PROJECT_ROOT.parent
DEFAULT_CANDIDATE = PROJECT_ROOT / "build/web"
DEFAULT_OUTPUT = PROJECT_ROOT / "build/rollback"
REQUIRED_FILES = frozenset(
    {"index.html", "index.js", "index.wasm", "index.pck", "release-candidate.json"}
)


@dataclass(frozen=True)
class Candidate:
    directory: Path
    metadata: dict
    files: dict[str, dict[str, int | str]]


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _file_entry(path: Path) -> dict[str, int | str]:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": _sha256(data)}


def _run(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, capture_output=True, text=True, check=False)


def _git_text(*args: str) -> str:
    result = _run(["git", *args], REPO_ROOT)
    if result.returncode != 0:
        raise RuntimeError((result.stderr or result.stdout).strip())
    return result.stdout.strip()


def _safe_output_directory(raw: Path) -> Path:
    output = raw if raw.is_absolute() else PROJECT_ROOT / raw
    output = output.resolve()
    build_root = (PROJECT_ROOT / "build").resolve()
    if output == build_root or build_root not in output.parents:
        raise ValueError(f"output must be a child of {build_root}")
    return output


def _load_candidate(directory: Path) -> Candidate:
    directory = directory.resolve()
    if directory != DEFAULT_CANDIDATE.resolve():
        raise ValueError(f"candidate must be the canonical directory: {DEFAULT_CANDIDATE}")
    metadata_path = directory / "release-candidate.json"
    if not metadata_path.is_file():
        raise FileNotFoundError(f"candidate metadata missing: {metadata_path}")
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    revision = str(metadata.get("revision", ""))
    if (
        metadata.get("project") != "project-a"
        or metadata.get("project_dirty") is not False
        or metadata.get("reproducible") is not True
        or len(revision) != 40
    ):
        raise ValueError("candidate is not a clean reproducible project-a artifact")
    if revision != _git_text("rev-parse", "HEAD"):
        raise ValueError("candidate revision does not match HEAD; rebuild before freezing rollback")
    if _git_text("status", "--porcelain", "--untracked-files=all", "--", "project-a"):
        raise ValueError("project-a is dirty; commit before freezing rollback")

    files = {
        path.relative_to(directory).as_posix(): _file_entry(path)
        for path in sorted(directory.rglob("*"))
        if path.is_file()
    }
    if not REQUIRED_FILES.issubset(files):
        raise ValueError(f"candidate is missing required files: {sorted(REQUIRED_FILES - files.keys())}")
    recorded = metadata.get("artifact_manifest", {})
    for name, entry in recorded.items():
        actual = files.get(name)
        if actual is None or actual["sha256"] != entry.get("sha256"):
            raise ValueError(f"candidate payload does not match release manifest: {name}")
    return Candidate(directory=directory, metadata=metadata, files=files)


def _archive_bytes(candidate: Candidate) -> bytes:
    raw = BytesIO()
    with gzip.GzipFile(fileobj=raw, mode="wb", filename="", compresslevel=9, mtime=0) as compressed:
        with tarfile.open(fileobj=compressed, mode="w", format=tarfile.PAX_FORMAT) as archive:
            for relative in sorted(candidate.files):
                data = (candidate.directory / relative).read_bytes()
                info = tarfile.TarInfo(name=f"web/{relative}")
                info.size = len(data)
                info.mode = 0o644
                info.mtime = 0
                info.uid = 0
                info.gid = 0
                info.uname = ""
                info.gname = ""
                archive.addfile(info, BytesIO(data))
    return raw.getvalue()


def _safe_member_path(member: tarfile.TarInfo) -> PurePosixPath:
    path = PurePosixPath(member.name)
    if (
        member.name.startswith("/")
        or path.is_absolute()
        or ".." in path.parts
        or not member.isfile()
        or len(path.parts) < 2
        or path.parts[0] != "web"
    ):
        raise ValueError(f"unsafe rollback archive member: {member.name}")
    return path


def _rehearse(archive_path: Path, candidate: Candidate) -> None:
    with tempfile.TemporaryDirectory(prefix="project-a-rollback-rehearsal-") as temporary:
        rehearsal_root = Path(temporary)
        restored_web = rehearsal_root / "web"
        with tarfile.open(archive_path, mode="r:gz") as archive:
            members = archive.getmembers()
            restored_names: set[str] = set()
            for member in members:
                path = _safe_member_path(member)
                relative = PurePosixPath(*path.parts[1:]).as_posix()
                restored_names.add(relative)
                destination = rehearsal_root.joinpath(*path.parts)
                destination.parent.mkdir(parents=True, exist_ok=True)
                stream = archive.extractfile(member)
                if stream is None:
                    raise ValueError(f"rollback member has no payload: {member.name}")
                destination.write_bytes(stream.read())
        if restored_names != set(candidate.files):
            raise ValueError("restored rollback file set differs from frozen candidate")
        for relative, expected in candidate.files.items():
            actual = _file_entry(restored_web / relative)
            if actual != expected:
                raise ValueError(f"restored rollback hash differs: {relative}")
        audit = _run(
            [
                sys.executable,
                str(PROJECT_ROOT / "tools/release_audit.py"),
                "--artifact-dir",
                str(restored_web),
            ],
            REPO_ROOT,
        )
        if audit.returncode != 0:
            sys.stdout.write(audit.stdout)
            sys.stderr.write(audit.stderr)
            raise RuntimeError("restored rollback artifact failed release audit")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--rehearse", action="store_true")
    arguments = parser.parse_args()

    candidate = _load_candidate(arguments.candidate)
    output = _safe_output_directory(arguments.output)
    output.mkdir(parents=True, exist_ok=True)
    revision = str(candidate.metadata["revision"])
    archive_path = output / f"project-a-web-{revision[:12]}.tar.gz"
    manifest_path = output / f"project-a-web-{revision[:12]}.rollback.json"

    first = _archive_bytes(candidate)
    second = _archive_bytes(candidate)
    if first != second:
        raise RuntimeError("two rollback packages differ; archive is not deterministic")
    archive_path.write_bytes(first)
    rollback_manifest = {
        "schema_version": 1,
        "project": "project-a",
        "revision": revision,
        "version": candidate.metadata["version"],
        "godot_version": candidate.metadata["godot_version"],
        "archive": archive_path.name,
        "archive_bytes": len(first),
        "archive_sha256": _sha256(first),
        "files": candidate.files,
        "rehearsed": bool(arguments.rehearse),
    }
    manifest_path.write_text(
        json.dumps(rollback_manifest, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    if arguments.rehearse:
        _rehearse(archive_path, candidate)
    print(
        "ROLLBACK_PACKAGE_READY: "
        f"revision={revision} archive={archive_path} sha256={rollback_manifest['archive_sha256']} "
        f"files={len(candidate.files)} rehearsed={arguments.rehearse}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, json.JSONDecodeError, OSError, RuntimeError, ValueError) as error:
        print(f"ROLLBACK_PACKAGE_FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
