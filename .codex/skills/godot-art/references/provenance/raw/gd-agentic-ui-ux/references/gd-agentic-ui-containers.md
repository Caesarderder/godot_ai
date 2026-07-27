---
name: gd-agentic-ui-containers
description: "Use when applying the godot-ui-containers capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-ui-containers

This Builda skill adapts the upstream `godot-ui-containers` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: ux-interface-role
- Canonical Builda owners: **responsive-ui**

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

- [`animated_container_shuffle.gd`](../scripts/gd-agentic-ui-containers/animated_container_shuffle.gd)
- [`aspect_ratio_mini_map.gd`](../scripts/gd-agentic-ui-containers/aspect_ratio_mini_map.gd)
- [`container_size_flags_pro.gd`](../scripts/gd-agentic-ui-containers/container_size_flags_pro.gd)
- [`custom_radial_container.gd`](../scripts/gd-agentic-ui-containers/custom_radial_container.gd)
- [`dynamic_tab_manager.gd`](../scripts/gd-agentic-ui-containers/dynamic_tab_manager.gd)
- [`performance_anchor_layout.gd`](../scripts/gd-agentic-ui-containers/performance_anchor_layout.gd)
- [`responsive_grid.gd`](../scripts/gd-agentic-ui-containers/responsive_grid.gd)
- [`responsive_inventory_grid.gd`](../scripts/gd-agentic-ui-containers/responsive_inventory_grid.gd)
- [`responsive_layout_builder.gd`](../scripts/gd-agentic-ui-containers/responsive_layout_builder.gd)
- [`responsive_tag_cloud.gd`](../scripts/gd-agentic-ui-containers/responsive_tag_cloud.gd)
- [`terminal_autoscroll.gd`](../scripts/gd-agentic-ui-containers/terminal_autoscroll.gd)
- [`viewport_3d_preview.gd`](../scripts/gd-agentic-ui-containers/viewport_3d_preview.gd)
- [`virtual_list.gd`](../scripts/gd-agentic-ui-containers/virtual_list.gd)

<!-- builda-script-index:end -->
