---
name: gd-agentic-camera-systems
description: "Use when applying the godot-camera-systems capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-camera-systems

This Builda skill adapts the upstream `godot-camera-systems` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: gameplay-development-role
- Canonical Builda owners: **camera-system**

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

- [`camera_follow_2d.gd`](../scripts/gd-agentic-camera-systems/camera_follow_2d.gd)
- [`camera_shake_trauma.gd`](../scripts/gd-agentic-camera-systems/camera_shake_trauma.gd)
- [`camera_shake_trauma_pro.gd`](../scripts/gd-agentic-camera-systems/camera_shake_trauma_pro.gd)
- [`camera_state_machine.gd`](../scripts/gd-agentic-camera-systems/camera_state_machine.gd)
- [`cinematic_framing_logic.gd`](../scripts/gd-agentic-camera-systems/cinematic_framing_logic.gd)
- [`deadzone_drag_margins.gd`](../scripts/gd-agentic-camera-systems/deadzone_drag_margins.gd)
- [`first_person_sway.gd`](../scripts/gd-agentic-camera-systems/first_person_sway.gd)
- [`framing_box_camera_2d.gd`](../scripts/gd-agentic-camera-systems/framing_box_camera_2d.gd)
- [`juice_camera.gd`](../scripts/gd-agentic-camera-systems/juice_camera.gd)
- [`minimap_viewport_manager.gd`](../scripts/gd-agentic-camera-systems/minimap_viewport_manager.gd)
- [`occlusion_aware_camera_3d.gd`](../scripts/gd-agentic-camera-systems/occlusion_aware_camera_3d.gd)
- [`phantom_decoupling.gd`](../scripts/gd-agentic-camera-systems/phantom_decoupling.gd)
- [`remote_transform_decoupling.gd`](../scripts/gd-agentic-camera-systems/remote_transform_decoupling.gd)
- [`split_screen_setup.gd`](../scripts/gd-agentic-camera-systems/split_screen_setup.gd)
- [`spring_lerp_camera_3d.gd`](../scripts/gd-agentic-camera-systems/spring_lerp_camera_3d.gd)
- [`trauma_debugger.gd`](../scripts/gd-agentic-camera-systems/trauma_debugger.gd)
- [`zoom_damping_controller.gd`](../scripts/gd-agentic-camera-systems/zoom_damping_controller.gd)

<!-- builda-script-index:end -->
