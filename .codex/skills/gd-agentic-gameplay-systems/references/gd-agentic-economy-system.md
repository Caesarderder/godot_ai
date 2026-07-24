---
name: gd-agentic-economy-system
description: "Use when applying the godot-economy-system capability through Builda's Godot 4.6 GDScript Web skill system"
---

# gd-agentic-economy-system

This Builda skill adapts the upstream `godot-economy-system` capability as a routing and implementation guide for Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime. Available upstream script prototypes are indexed below and must be reviewed before adaptation.

## Classification

- Skill book: data-release-role
- Canonical Builda owners: **game-economy**

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

- [`currency_label_sync.gd`](../scripts/gd-agentic-economy-system/currency_label_sync.gd)
- [`currency_pickup_effect.gd`](../scripts/gd-agentic-economy-system/currency_pickup_effect.gd)
- [`currency_resource.gd`](../scripts/gd-agentic-economy-system/currency_resource.gd)
- [`dynamic_price_modifier.gd`](../scripts/gd-agentic-economy-system/dynamic_price_modifier.gd)
- [`economy_logger.gd`](../scripts/gd-agentic-economy-system/economy_logger.gd)
- [`economy_persistence_handler.gd`](../scripts/gd-agentic-economy-system/economy_persistence_handler.gd)
- [`item_value_estimator.gd`](../scripts/gd-agentic-economy-system/item_value_estimator.gd)
- [`loot_drop_economy_bridge.gd`](../scripts/gd-agentic-economy-system/loot_drop_economy_bridge.gd)
- [`loot_table_weighted.gd`](../scripts/gd-agentic-economy-system/loot_table_weighted.gd)
- [`shop_item_data.gd`](../scripts/gd-agentic-economy-system/shop_item_data.gd)
- [`shop_system_logic.gd`](../scripts/gd-agentic-economy-system/shop_system_logic.gd)
- [`trade_contract_resource.gd`](../scripts/gd-agentic-economy-system/trade_contract_resource.gd)
- [`transaction_manager.gd`](../scripts/gd-agentic-economy-system/transaction_manager.gd)
- [`wallet_manager_singleton.gd`](../scripts/gd-agentic-economy-system/wallet_manager_singleton.gd)

<!-- builda-script-index:end -->
