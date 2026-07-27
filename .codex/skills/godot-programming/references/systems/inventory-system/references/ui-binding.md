# UI Binding (Drag & Drop Inventory)

Reference for `skills/inventory-system/SKILL.md` — full drag-and-drop inventory UI (slot grid, ItemDrag, hover preview, GDScript).

> ← Back to [SKILL.md](../SKILL.md)

---
## 6. UI Binding

### Scene Structure

```
InventoryUI (Control)
  └─ GridContainer          ← auto-fills slots
       └─ SlotUI × N (Button)
            ├─ TextureRect  ← item icon
            └─ Label        ← quantity ("x3")
```

### GDScript

```gdscript
# inventory_ui.gd
class_name InventoryUI
extends Control

@export var slot_scene: PackedScene  # scene for SlotUI
@export var inventory: Inventory

@onready var grid: GridContainer = $GridContainer

var _slot_nodes: Array[SlotUI] = []


func _ready() -> void:
    assert(inventory != null, "InventoryUI: inventory must be assigned")
    inventory.inventory_changed.connect(_refresh)
    _build_grid()
    _refresh()


func _build_grid() -> void:
    for child in grid.get_children():
        child.queue_free()
    _slot_nodes.clear()

    for i in inventory.slots.size():
        var slot_ui: SlotUI = slot_scene.instantiate()
        grid.add_child(slot_ui)
        slot_ui.slot_index = i
        slot_ui.inventory  = inventory
        _slot_nodes.append(slot_ui)


func _refresh() -> void:
    for i in _slot_nodes.size():
        _slot_nodes[i].update_display(inventory.slots[i])
```

```gdscript
# slot_ui.gd
class_name SlotUI
extends Button

var slot_index: int   = -1
var inventory: Inventory

@onready var icon_rect: TextureRect = $TextureRect
@onready var qty_label: Label       = $Label


func update_display(slot: InventorySlot) -> void:
    if slot.is_empty():
        icon_rect.texture = null
        qty_label.text    = ""
    else:
        icon_rect.texture = slot.item.icon
        qty_label.text    = "x%d" % slot.quantity if slot.quantity > 1 else ""


# ── Drag-and-drop ────────────────────────────────────────────────────────────

func _get_drag_data(_at_position: Vector2) -> Variant:
    var slot := inventory.slots[slot_index]
    if slot.is_empty():
        return null

    # Preview
    var preview := TextureRect.new()
    preview.texture         = slot.item.icon
    preview.expand_mode     = TextureRect.EXPAND_FIT_WIDTH
    preview.custom_minimum_size = Vector2(48, 48)
    set_drag_preview(preview)

    return {"from_index": slot_index, "item": slot.item, "quantity": slot.quantity}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("from_index")


func _drop_data(_at_position: Vector2, data: Dictionary) -> void:
    var from: int = data["from_index"]
    var to:   int = slot_index
    if from == to:
        return

    # Swap slot contents directly (bypass add/remove to avoid signals noise)
    var from_slot := inventory.slots[from]
    var to_slot   := inventory.slots[to]

    var tmp_item := to_slot.item
    var tmp_qty  := to_slot.quantity
    to_slot.item     = from_slot.item
    to_slot.quantity = from_slot.quantity
    from_slot.item     = tmp_item
    from_slot.quantity = tmp_qty

    inventory.inventory_changed.emit()
```




---
