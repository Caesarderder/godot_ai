#!/usr/bin/env python3
"""Local Web release artifact audit for Project A.

This script intentionally proves only local source/artifact facts. It does not
claim Builda control, mobile-device QA, hosting, legal approval, or production
privacy evidence.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]


REQUIRED_RELEASE_FILES = [
    "LICENSES.md",
    "PRIVACY.md",
    "FAN-CONTENT-NOTICE.md",
    "RELEASE_CHECKLIST.md",
    "version.json",
    "offline.html",
    "web-icon.svg",
]

REQUIRED_ARTIFACTS = [
    "index.html",
    "index.js",
    "index.wasm",
    "index.pck",
    "release-candidate.json",
]

INITIAL_PAYLOAD_FILES = [
    "index.html",
    "index.js",
    "index.wasm",
    "index.pck",
]
INITIAL_PAYLOAD_GZIP_TARGET_BYTES = 20 * 1024 * 1024
INITIAL_PAYLOAD_GZIP_HARD_LIMIT_BYTES = 30 * 1024 * 1024

FORBIDDEN_ARTIFACT_SUFFIXES = {
    ".gd",
    ".godot",
    ".import",
    ".tscn",
    ".tres",
    ".uid",
}

REQUIRED_PRESET_SNIPPETS = {
    'name="Web"': "Web preset exists",
    'platform="Web"': "Web platform selected",
    'export_path="build/web/index.html"': "canonical Web export path",
    'include_filter="release/*"': "release materials included",
    'exclude_filter="artifacts/*,build/*,tools/*,tests/*,scripts/main.gd"': "debug artifacts, tools, tests, and legacy App Shell excluded",
    'variant/thread_support=false': "single-thread Web export",
    'variant/extensions_support=false': "GDExtension disabled for Web",
    "html/canvas_resize_policy=2": "adaptive canvas resize",
    "html/focus_canvas_on_start=true": "canvas focus on start",
    "progressive_web_app/enabled=true": "PWA metadata enabled",
    "progressive_web_app/ensure_cross_origin_isolation_headers=false": "no service-worker COOP/COEP workaround for threadless build",
    'progressive_web_app/offline_page="release/offline.html"': "offline page configured",
}

REQUIRED_PROJECT_SNIPPETS = {
    'config/features=PackedStringArray("4.6", "GL Compatibility")': "project declares Godot 4.6 GL Compatibility feature",
    'renderer/rendering_method="gl_compatibility"': "desktop renderer is Compatibility",
    'renderer/rendering_method.mobile="gl_compatibility"': "mobile renderer is Compatibility",
    'run/main_scene="res://scenes/screens/main.tscn"': "main scene configured",
}

EXTERNAL_BLOCKERS = [
    "Builda-controlled runtime/template identity was not proven by this script.",
    "Final HTTPS deployment URL and production headers were not tested.",
    "Chrome Android and Safari iOS real-device smoke were not tested.",
    "Production-origin persistence was not tested; local Chrome private-context and fully blocked IndexedDB behavior are covered separately.",
    "Final legal/IP/store review is still required.",
    "Monitoring and rollback rehearsal are still required.",
]


def _artifact_entry(path: Path) -> dict[str, int | str]:
    data = path.read_bytes()
    return {
        "bytes": len(data),
        "gzip_9_bytes": len(gzip.compress(data, compresslevel=9, mtime=0)),
        "sha256": hashlib.sha256(data).hexdigest(),
    }


def _run_godot_version() -> str:
    godot_executable = shutil.which("godot") or shutil.which("godot.cmd") or shutil.which("godot.exe")
    if not godot_executable:
        return "UNAVAILABLE: godot executable not found on PATH"
    try:
        completed = subprocess.run(
            [godot_executable, "--version"],
            check=False,
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT,
            timeout=20,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return f"UNAVAILABLE: {exc}"
    output = (completed.stdout or completed.stderr).strip()
    if completed.returncode != 0:
        return f"FAILED({completed.returncode}): {output}"
    return output


def _load_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _check_source() -> tuple[list[str], list[str], dict]:
    passed: list[str] = []
    failed: list[str] = []
    evidence: dict = {}

    preset_path = PROJECT_ROOT / "export_presets.cfg"
    if not preset_path.exists():
        failed.append("missing export_presets.cfg")
        preset_text = ""
    else:
        preset_text = _load_text(preset_path)
        evidence["export_presets_cfg"] = str(preset_path)

    for snippet, label in REQUIRED_PRESET_SNIPPETS.items():
        if snippet in preset_text:
            passed.append(label)
        else:
            failed.append(f"missing preset setting: {snippet}")

    if "<<<<<<<" in preset_text or ">>>>>>>" in preset_text:
        failed.append("export_presets.cfg contains conflict markers")
    else:
        passed.append("export_presets.cfg has no conflict markers")

    project_path = PROJECT_ROOT / "project.godot"
    if not project_path.exists():
        failed.append("missing project.godot")
        project_text = ""
    else:
        project_text = _load_text(project_path)
        evidence["project_godot"] = str(project_path)
    if "<<<<<<<" in project_text or ">>>>>>>" in project_text:
        failed.append("project.godot contains conflict markers")
    elif project_text:
        passed.append("project.godot has no conflict markers")
    for snippet, label in REQUIRED_PROJECT_SNIPPETS.items():
        if snippet in project_text:
            passed.append(label)
        else:
            failed.append(f"missing project setting: {snippet}")

    release_dir = PROJECT_ROOT / "release"
    for relative in REQUIRED_RELEASE_FILES:
        path = release_dir / relative
        if path.exists() and path.stat().st_size > 0:
            passed.append(f"release/{relative} present")
        else:
            failed.append(f"missing or empty release/{relative}")

    version_path = release_dir / "version.json"
    if version_path.exists():
        try:
            version_data = json.loads(_load_text(version_path))
            evidence["version"] = version_data
            if version_data.get("web_threads") is False:
                passed.append("version.json declares web_threads=false")
            else:
                failed.append("version.json does not declare web_threads=false")
            if version_data.get("privacy_claim"):
                passed.append("version.json declares privacy claim")
            else:
                failed.append("version.json missing privacy claim")
        except json.JSONDecodeError as exc:
            failed.append(f"version.json is invalid JSON: {exc}")

    privacy_text = _load_text(release_dir / "PRIVACY.md") if (release_dir / "PRIVACY.md").exists() else ""
    for phrase in ["No analytics SDK", "No telemetry endpoint", "No cookies", "local progress"]:
        if phrase in privacy_text:
            passed.append(f"privacy statement includes: {phrase}")
        else:
            failed.append(f"privacy statement missing: {phrase}")

    licenses_text = _load_text(release_dir / "LICENSES.md") if (release_dir / "LICENSES.md").exists() else ""
    for phrase in ["NotoSansCJKsc-Regular.otf", "Program-generated", "notofonts/noto-cjk", "Sans/LICENSE"]:
        if phrase in licenses_text:
            passed.append(f"license inventory includes: {phrase}")
        else:
            failed.append(f"license inventory missing: {phrase}")
    ofl_path = PROJECT_ROOT / "assets" / "fonts" / "OFL.txt"
    ofl_text = _load_text(ofl_path) if ofl_path.exists() else ""
    if "SIL OPEN FONT LICENSE Version 1.1" in ofl_text:
        passed.append("font OFL 1.1 text present")
    else:
        failed.append("font OFL 1.1 text missing")
    if "<Copyright Holder>" in ofl_text or "<dates>" in ofl_text:
        failed.append("font OFL contains unresolved placeholder fields")
    else:
        passed.append("font OFL has no unresolved placeholder fields")

    fan_text = _load_text(release_dir / "FAN-CONTENT-NOTICE.md") if (release_dir / "FAN-CONTENT-NOTICE.md").exists() else ""
    for phrase in ["non-official", "not affiliated", "legal/product review"]:
        if phrase in fan_text:
            passed.append(f"fan-content notice includes: {phrase}")
        else:
            failed.append(f"fan-content notice missing: {phrase}")

    evidence["godot_version"] = _run_godot_version()
    if evidence["godot_version"].startswith("4.6.3."):
        passed.append("Godot executable reports 4.6.3")
    else:
        failed.append(f"Godot executable is not proven as 4.6.3: {evidence['godot_version']}")

    return passed, failed, evidence


def _check_artifacts(artifact_dir: Path | None) -> tuple[list[str], list[str], dict]:
    passed: list[str] = []
    failed: list[str] = []
    evidence: dict = {}

    if artifact_dir is None:
        return passed, failed, evidence

    if not artifact_dir.is_absolute():
        cwd_candidate = (Path.cwd() / artifact_dir).resolve()
        project_candidate = (PROJECT_ROOT / artifact_dir).resolve()
        artifact_dir = cwd_candidate if cwd_candidate.exists() else project_candidate
    evidence["artifact_dir"] = str(artifact_dir)
    if not artifact_dir.exists():
        failed.append(f"artifact directory does not exist: {artifact_dir}")
        return passed, failed, evidence

    shipped_files = sorted(
        path for path in artifact_dir.rglob("*")
        if path.is_file()
    )
    shipped_names = [path.relative_to(artifact_dir).as_posix() for path in shipped_files]
    forbidden_files = [
        name for name in shipped_names
        if Path(name).suffix.lower() in FORBIDDEN_ARTIFACT_SUFFIXES
    ]
    evidence["shipped_files"] = shipped_names
    evidence["forbidden_source_files"] = forbidden_files
    if forbidden_files:
        failed.append(f"forbidden editor/source sidecars shipped: {forbidden_files}")
    else:
        passed.append("no Godot editor/source sidecars shipped")

    manifest: dict[str, dict[str, int | str]] = {}
    for name in REQUIRED_ARTIFACTS:
        path = artifact_dir / name
        if not path.exists() or path.stat().st_size <= 0:
            failed.append(f"missing or empty artifact: {name}")
            continue
        manifest[name] = _artifact_entry(path)
        passed.append(f"artifact present with hash: {name}")

    candidate_path = artifact_dir / "release-candidate.json"
    if candidate_path.exists():
        try:
            candidate = json.loads(_load_text(candidate_path))
            evidence["release_candidate"] = candidate
            declared = candidate.get("artifact_manifest", {})
            actual = {
                path.relative_to(artifact_dir).as_posix(): _artifact_entry(path)
                for path in shipped_files
                if path.name != "release-candidate.json"
            }
            if declared == actual:
                passed.append("release candidate manifest matches every shipped payload file")
            else:
                failed.append("release candidate manifest does not match shipped payload files")
            if candidate.get("reproducible") is True:
                passed.append("release candidate records a matching second clean export")
            else:
                failed.append("release candidate does not prove a matching second clean export")
            if candidate.get("project_dirty") is False:
                passed.append("release candidate records a clean project-a source scope")
            else:
                failed.append("release candidate was built from a dirty project-a source scope")
        except (json.JSONDecodeError, OSError) as exc:
            failed.append(f"release-candidate.json is invalid: {exc}")

    initial_entries = [
        _artifact_entry(artifact_dir / name)
        for name in INITIAL_PAYLOAD_FILES
        if (artifact_dir / name).is_file()
    ]
    initial_raw_bytes = sum(int(entry["bytes"]) for entry in initial_entries)
    initial_gzip_bytes = sum(int(entry["gzip_9_bytes"]) for entry in initial_entries)
    payload_budget = {
        "files": INITIAL_PAYLOAD_FILES,
        "raw_bytes": initial_raw_bytes,
        "gzip_9_bytes": initial_gzip_bytes,
        "target_bytes": INITIAL_PAYLOAD_GZIP_TARGET_BYTES,
        "hard_limit_bytes": INITIAL_PAYLOAD_GZIP_HARD_LIMIT_BYTES,
        "target_met": initial_gzip_bytes <= INITIAL_PAYLOAD_GZIP_TARGET_BYTES,
        "hard_limit_met": initial_gzip_bytes <= INITIAL_PAYLOAD_GZIP_HARD_LIMIT_BYTES,
    }
    evidence["initial_payload_budget"] = payload_budget
    if payload_budget["hard_limit_met"]:
        passed.append(
            "gzip-9 initial payload is within the 30 MiB hard limit"
        )
    else:
        failed.append(
            f"gzip-9 initial payload exceeds 30 MiB: {initial_gzip_bytes} bytes"
        )
    if payload_budget["target_met"]:
        passed.append("gzip-9 initial payload meets the 20 MiB target")
    else:
        evidence["initial_payload_target_gap_bytes"] = (
            initial_gzip_bytes - INITIAL_PAYLOAD_GZIP_TARGET_BYTES
        )

    workers = sorted(path.name for path in artifact_dir.glob("*.worker.js"))
    service_workers = [name for name in workers if name.endswith(".service.worker.js")]
    runtime_workers = [name for name in workers if name not in service_workers]
    evidence["worker_js"] = workers
    evidence["service_worker_js"] = service_workers
    evidence["runtime_worker_js"] = runtime_workers
    if runtime_workers:
        failed.append(f"unexpected threaded runtime worker artifacts: {runtime_workers}")
    else:
        passed.append("no threaded runtime .worker.js artifacts")
    if service_workers:
        passed.append(f"PWA service worker present: {service_workers}")

    html_path = artifact_dir / "index.html"
    if html_path.exists():
        html_text = _load_text(html_path)
        if "const GODOT_THREADS_ENABLED = false;" in html_text:
            passed.append("index.html declares GODOT_THREADS_ENABLED=false")
        else:
            failed.append("index.html does not declare GODOT_THREADS_ENABLED=false")
        for phrase in ["viewport-fit=cover", "theme-color", "apple-mobile-web-app-capable"]:
            if phrase in html_text:
                passed.append(f"index.html includes mobile head metadata: {phrase}")
            else:
                failed.append(f"index.html missing mobile head metadata: {phrase}")
        if "manifest" in html_text or "serviceWorker" in html_text:
            passed.append("index.html contains PWA/service-worker bootstrap references")
        else:
            failed.append("index.html has no observed PWA/service-worker bootstrap reference")

    pwa_candidates = sorted(path.name for path in artifact_dir.glob("*service_worker*")) + sorted(path.name for path in artifact_dir.glob("*manifest*"))
    evidence["pwa_files"] = pwa_candidates
    if pwa_candidates:
        passed.append(f"PWA auxiliary files present: {pwa_candidates}")
    else:
        failed.append("PWA auxiliary files not found in artifact directory")

    evidence["artifact_manifest"] = manifest
    return passed, failed, evidence


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifact-dir", default=None, help="Path to exported Web artifact directory, for example build/web")
    parser.add_argument("--json", action="store_true", help="Emit JSON only")
    args = parser.parse_args()

    source_passed, source_failed, source_evidence = _check_source()
    artifact_passed, artifact_failed, artifact_evidence = _check_artifacts(Path(args.artifact_dir) if args.artifact_dir else None)

    failed = source_failed + artifact_failed
    passed = source_passed + artifact_passed
    result = {
        "verdict": "PASS_LOCAL_ARTIFACT_AUDIT" if not failed else "FAIL_LOCAL_ARTIFACT_AUDIT",
        "passed": passed,
        "failed": failed,
        "evidence": {**source_evidence, **artifact_evidence},
        "external_blockers": EXTERNAL_BLOCKERS,
    }

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"VERDICT: {result['verdict']}")
        print("\nPASSED:")
        for item in passed:
            print(f"- {item}")
        print("\nFAILED:")
        for item in failed:
            print(f"- {item}")
        print("\nEVIDENCE:")
        print(json.dumps(result["evidence"], ensure_ascii=False, indent=2))
        print("\nEXTERNAL BLOCKERS:")
        for item in EXTERNAL_BLOCKERS:
            print(f"- {item}")

    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
