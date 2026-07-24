---
name: gd-agentic-inventory-system
description: "Use when applying the godot-inventory-system capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-inventory-system

This Builda skill adapts the upstream `godot-inventory-system` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: data-release-role
- Canonical Builda owners: **inventory-system**

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

- [`consumable_item_logic.gd`](../scripts/gd-agentic-inventory-system/consumable_item_logic.gd)
- [`drag_and_drop_slot.gd`](../scripts/gd-agentic-inventory-system/drag_and_drop_slot.gd)
- [`grid_inventory_logic.gd`](../scripts/gd-agentic-inventory-system/grid_inventory_logic.gd)
- [`inventory_data_resource.gd`](../scripts/gd-agentic-inventory-system/inventory_data_resource.gd)
- [`inventory_grid.gd`](../scripts/gd-agentic-inventory-system/inventory_grid.gd)
- [`inventory_item_resource.gd`](../scripts/gd-agentic-inventory-system/inventory_item_resource.gd)
- [`inventory_persistence.gd`](../scripts/gd-agentic-inventory-system/inventory_persistence.gd)
- [`inventory_ui_controller.gd`](../scripts/gd-agentic-inventory-system/inventory_ui_controller.gd)
- [`item_database_loader.gd`](../scripts/gd-agentic-inventory-system/item_database_loader.gd)
- [`item_pickup_node.gd`](../scripts/gd-agentic-inventory-system/item_pickup_node.gd)
- [`item_slot_data.gd`](../scripts/gd-agentic-inventory-system/item_slot_data.gd)
- [`loot_table_resource.gd`](../scripts/gd-agentic-inventory-system/loot_table_resource.gd)

<!-- builda-script-index:end -->
