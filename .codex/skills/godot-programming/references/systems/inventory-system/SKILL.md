---
name: inventory-system
description: Use when building Resource-based items, slot management, stacking, equipment, serialization, and inventory UI in Godot 4.6 GDScript Web projects
---

# Inventory Systems in Godot 4.6

Use Godot 4.6.x GDScript APIs that work in Builda's single-threaded Web export.

> **Related skills:** **resource-pattern** for custom Resource data containers, **save-load** for inventory serialization, **godot-architecture** for local inventory change signals, and **hud-system** for inventory UI display.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                         │
│   InventoryUI (Control)                                 │
│     └─ GridContainer                                    │
│           └─ SlotUI × N (Button)                        │
│                 └─ TextureRect (icon) + Label (qty)     │
│                                                         │
│   Connects to: inventory_changed signal                 │
│   Drag-and-drop via _get_drag_data / _drop_data         │
└───────────────────────┬─────────────────────────────────┘
                        │ reads / mutates
┌───────────────────────▼─────────────────────────────────┐
│                    Inventory (Node)                      │
│   slots: Array[InventorySlot]                           │
│   add_item(item, qty) → leftover: int                   │
│   remove_item(item, qty)                                │
│   has_item(item, qty) → bool                            │
│   get_item_count(item) → int                            │
│                                                         │
│   signals: inventory_changed                            │
│             item_added(item, quantity)                  │
│             item_removed(item, quantity)                │
└───────────────────────┬─────────────────────────────────┘
                        │ references
┌───────────────────────▼─────────────────────────────────┐
│                   Data Layer (Resources)                 │
│   ItemData (Resource)                                   │
│     id, name, description, icon, max_stack_size,        │
│     item_type enum                                      │
│                                                         │
│   InventorySlot (inner class / Resource)                │
│     item: ItemData, quantity: int                       │
└─────────────────────────────────────────────────────────┘
```

---

## 2. ItemData Resource

Define items as Resources so they live in `.tres` files, are shareable across scenes, and benefit from full editor integration.

### GDScript

```gdscript
# item_data.gd
class_name ItemData
extends Resource

enum ItemType {
    CONSUMABLE,
    EQUIPMENT,
    MATERIAL,
    KEY_ITEM,
}

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var max_stack_size: int = 99
@export var item_type: ItemType = ItemType.MATERIAL
```

Create item assets: **res://items/potion_health.tres**, set `id = "potion_health"`, etc.

> Use `[GlobalClass]` so the Inspector dropdown shows `ItemData` as a resource type when creating `.tres` files.

---

## 3. Inventory Class

### GDScript

```gdscript
# inventory.gd
class_name Inventory
extends Node

signal inventory_changed
signal item_added(item: ItemData, quantity: int)
signal item_removed(item: ItemData, quantity: int)

@export var capacity: int = 20

var slots: Array[InventorySlot] = []


func _ready() -> void:
    slots.resize(capacity)
    for i in capacity:
        slots[i] = InventorySlot.new()


# Returns the number of items that could NOT be added (leftover).
func add_item(item: ItemData, quantity: int = 1) -> int:
    var remaining := quantity

    # Fill existing stacks first
    for slot in slots:
        if remaining <= 0:
            break
        if not slot.is_empty() and slot.item == item:
            remaining = slot.add_to_stack(remaining)

    # Open empty slots next
    for slot in slots:
        if remaining <= 0:
            break
        if slot.is_empty():
            slot.item = item
            remaining = slot.add_to_stack(remaining)

    var added := quantity - remaining
    if added > 0:
        item_added.emit(item, added)
        inventory_changed.emit()

    return remaining


func remove_item(item: ItemData, quantity: int = 1) -> void:
    var remaining := quantity

    for slot in slots:
        if remaining <= 0:
            break
        if not slot.is_empty() and slot.item == item:
            var removed := mini(slot.quantity, remaining)
            slot.remove_from_stack(removed)
            remaining -= removed

    var actually_removed := quantity - remaining
    if actually_removed > 0:
        item_removed.emit(item, actually_removed)
        inventory_changed.emit()


func has_item(item: ItemData, quantity: int = 1) -> bool:
    return get_item_count(item) >= quantity


func get_item_count(item: ItemData) -> int:
    var total := 0
    for slot in slots:
        if not slot.is_empty() and slot.item == item:
            total += slot.quantity
    return total
```

---

## 4. InventorySlot

`InventorySlot` is a lightweight object tracking an item reference and its quantity. Define it as an inner GDScript class on `Inventory` or as a standalone `RefCounted` subclass.

### GDScript

```gdscript
# inventory_slot.gd  — or nest as inner class inside inventory.gd
class_name InventorySlot
extends RefCounted

var item: ItemData = null
var quantity: int   = 0


func is_empty() -> bool:
    return item == null or quantity <= 0


func can_stack(new_item: ItemData) -> bool:
    return not is_empty() and item == new_item and quantity < item.max_stack_size


# Adds amount to this slot, capped at max_stack_size.
# Returns the leftover that did not fit.
func add_to_stack(amount: int) -> int:
    if item == null:
        push_error("InventorySlot.add_to_stack: slot has no item assigned")
        return amount
    var space    := item.max_stack_size - quantity
    var to_add   := mini(amount, space)
    quantity     += to_add
    return amount - to_add


# Removes amount from this slot. Clears the slot when quantity reaches zero.
func remove_from_stack(amount: int) -> void:
    quantity -= amount
    if quantity <= 0:
        quantity = 0
        item     = null
```

## 5. Equipment Extension

Add equipment slots (`HEAD`, `CHEST`, `WEAPON`, etc.) by extending the `Inventory` class with a typed slot map. Stat aggregation runs by summing `ItemData.stats` across equipped items; signal `equipment_changed` when slots change.

> See [references/equipment.md](references/equipment.md) for the GDScript `Equipment` class with `EquipmentSlotType` enum, equip/unequip API, and stat aggregation.

---

## 6. UI Binding

Slot-grid UI: a `GridContainer` of `Panel` slot widgets, each rendering one `InventorySlot`. Drag-and-drop uses `_get_drag_data` / `_drop_data` / `_can_drop_data` on the slot widget. The Inventory emits `inventory_changed`; the UI re-renders affected slots.

> See [references/ui-binding.md](references/ui-binding.md) for the GDScript slot widget, inventory grid layout, and tooltip wiring.

---

## 7. Serialization

Persist Inventory + Equipment as stable `item_id + quantity` records. Reload through `ItemRegistry`, which maps IDs to the current `ItemData` resources; save files must not depend on resource paths. A version field gates migration on load.

> See [references/serialization.md](references/serialization.md) for the GDScript save/load implementation with a `version` field and ConfigFile/JSON variants.

---

## 8. Implementation Checklist

- [ ] `ItemData` extends `Resource` with a stable `id` string set in the Inspector
- [ ] `ItemData` files live under `res://items/` and are committed to version control
- [ ] `Inventory.add_item()` returns leftover count; callers handle a full inventory
- [ ] `inventory_changed` signal drives all UI updates — UI never polls per-frame
- [ ] `InventorySlot.remove_from_stack()` clears `item` to `null` when quantity reaches 0
- [ ] Equipment slots keyed by `SlotType` enum, not by string, to catch typos at parse time
- [ ] `Equipment.get_total_stat()` is called when stats are needed, not cached unless profiling demands it
- [ ] Serialization stores `id + quantity` only — never full `ItemData` objects or resource paths
- [ ] `ItemRegistry` loads items at startup; all deserialization goes through it
- [ ] Drag-and-drop swaps slot contents directly then emits `inventory_changed` once
- [ ] `max_stack_size = 1` on `EQUIPMENT` and `KEY_ITEM` types to prevent stacking
- [ ] All `push_error()` messages include the class name and method for easy tracing

---
