---
name: gd-agentic-platform-web
description: "Use when applying the godot-platform-web capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-platform-web

This Builda skill adapts the upstream `godot-platform-web` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

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

- [`platform_web_patterns.gd`](../scripts/gd-agentic-platform-web/platform_web_patterns.gd)
- [`web_bridge_sync.gd`](../scripts/gd-agentic-platform-web/web_bridge_sync.gd)
- [`web_browser_input_guard.gd`](../scripts/gd-agentic-platform-web/web_browser_input_guard.gd)
- [`web_clipboard_interface.gd`](../scripts/gd-agentic-platform-web/web_clipboard_interface.gd)
- [`web_external_url_opener.gd`](../scripts/gd-agentic-platform-web/web_external_url_opener.gd)
- [`web_javascript_bridge_callback.gd`](../scripts/gd-agentic-platform-web/web_javascript_bridge_callback.gd)
- [`web_json_rpc_bridge.gd`](../scripts/gd-agentic-platform-web/web_json_rpc_bridge.gd)
- [`web_local_storage_wrapper.gd`](../scripts/gd-agentic-platform-web/web_local_storage_wrapper.gd)
- [`web_navigation_guard.gd`](../scripts/gd-agentic-platform-web/web_navigation_guard.gd)
- [`web_performance_profiler.gd`](../scripts/gd-agentic-platform-web/web_performance_profiler.gd)
- [`web_resource_lazy_loader.gd`](../scripts/gd-agentic-platform-web/web_resource_lazy_loader.gd)
- [`web_responsive_canvas_adaptor.gd`](../scripts/gd-agentic-platform-web/web_responsive_canvas_adaptor.gd)
- [`web_visibility_auto_pause.gd`](../scripts/gd-agentic-platform-web/web_visibility_auto_pause.gd)

<!-- builda-script-index:end -->
