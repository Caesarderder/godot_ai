#!/usr/bin/env python3
"""Local Web release artifact audit for Project A.

This script intentionally proves only local source/artifact facts. It does not
claim Builda control, mobile-device QA, hosting, legal approval, or production
privacy evidence.
"""

from __future__ import annotations

import argparse
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
]

REQUIRED_PRESET_SNIPPETS = {
    'name="Web"': "Web preset exists",
    'platform="Web"': "Web platform selected",
    'export_path="build/web/index.html"': "canonical Web export path",
    'include_filter="release/*"': "release materials included",
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
    "Production-origin persistence, blocked storage, and private browsing were not tested.",
    "Final legal/IP/store review is still required.",
    "Monitoring and rollback rehearsal are still required.",
]


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


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

    artifact_dir = artifact_dir if artifact_dir.is_absolute() else PROJECT_ROOT / artifact_dir
    evidence["artifact_dir"] = str(artifact_dir)
    if not artifact_dir.exists():
        failed.append(f"artifact directory does not exist: {artifact_dir}")
        return passed, failed, evidence

    manifest: dict[str, dict[str, int | str]] = {}
    for name in REQUIRED_ARTIFACTS:
        path = artifact_dir / name
        if not path.exists() or path.stat().st_size <= 0:
            failed.append(f"missing or empty artifact: {name}")
            continue
        manifest[name] = {
            "bytes": path.stat().st_size,
            "sha256": _sha256(path),
        }
        passed.append(f"artifact present with hash: {name}")

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
