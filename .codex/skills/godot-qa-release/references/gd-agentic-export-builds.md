---
name: gd-agentic-export-builds
description: "Use when applying the godot-export-builds capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-export-builds

This Builda skill adapts the upstream `godot-export-builds` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: data-release-role
- Canonical Builda owners: **game-web-release**, **resource-pattern**

## Use

1. Inspect the current project and select the smallest relevant canonical owner.
2. Apply this capability through existing Builda project, architecture, resource, save/load, asset, and review rules.
3. Reject native, editor-only, network-authority, credential, external-process, multithreaded, or unsupported API assumptions unless the project explicitly authorizes and validates them.
4. Verify Godot 4.6 parsing/import, Web Compatibility export, focused behavior, and the real runtime before claiming completion.

## Core protection

Do not modify or supersede **godot-project-setup**, **godot-architecture**, **gdscript-patterns**, **assets-pipeline**, **resource-pattern**, **save-load**, or **godot-code-review**. Project files, scene/UID identity, `res://`, `user://`, persistence, asset provenance, and review policy remain owned there.

Source classification: [GD-Agentic-Skills](https://github.com/thedivergentai/GD-Agentic-Skills), reviewed revision `42eea91671adb27b2822be94aa46345517803ffb`; upstream license: LGPL-3.0 (license text is not bundled).

<!-- builda-script-index:start -->

## Builda script prototypes

Inspect only the prototypes relevant to the current task. These files are preserved from the pinned upstream revision, but they are not pre-approved for direct execution or bulk copying; adapt them to Godot 4.6.x, GDScript, Web, Compatibility rendering, single-thread execution, and the current project boundary.

- [`export_android_signing_env.ps1`](../scripts/gd-agentic-export-builds/export_android_signing_env.ps1)
- [`export_build_size_report.gd`](../scripts/gd-agentic-export-builds/export_build_size_report.gd)
- [`export_ci_github_actions.yml`](../scripts/gd-agentic-export-builds/export_ci_github_actions.yml)
- [`export_custom_build_stripper.py`](../scripts/gd-agentic-export-builds/export_custom_build_stripper.py)
- [`export_feature_flag_manager.gd`](../scripts/gd-agentic-export-builds/export_feature_flag_manager.gd)
- [`export_headless_pipeline.ps1`](../scripts/gd-agentic-export-builds/export_headless_pipeline.ps1)
- [`export_macos_notarize_cmd.ps1`](../scripts/gd-agentic-export-builds/export_macos_notarize_cmd.ps1)
- [`export_pck_patch_loader.gd`](../scripts/gd-agentic-export-builds/export_pck_patch_loader.gd)
- [`export_post_process_hook.gd`](../scripts/gd-agentic-export-builds/export_post_process_hook.gd)
- [`export_steam_upload.ps1`](../scripts/gd-agentic-export-builds/export_steam_upload.ps1)
- [`export_universal_manager.gd`](../scripts/gd-agentic-export-builds/export_universal_manager.gd)
- [`export_version_sync.gd`](../scripts/gd-agentic-export-builds/export_version_sync.gd)
- [`headless_build.sh`](../scripts/gd-agentic-export-builds/headless_build.sh)
- [`version_manager.gd`](../scripts/gd-agentic-export-builds/version_manager.gd)

<!-- builda-script-index:end -->
