# Inventory Serialization

Reference for `skills/inventory-system/SKILL.md` — save/load via Resource → JSON or ConfigFile, with versioning. GDScript.

> ← Back to [SKILL.md](../SKILL.md)

---
## 7. Serialization

Save inventories as `item_id + quantity` pairs. Never serialize the full `ItemData` Resource — instead, look up items at load time from a preloaded registry. This keeps save files small and decoupled from resource paths.

### GDScript

```gdscript
# item_registry.gd — add as autoload named ItemRegistry
extends Node

# Populate by scanning a folder, or assign manually in _ready().
var _items: Dictionary = {}  # id → ItemData


func _ready() -> void:
    _load_all("res://items/")


func _load_all(folder: String) -> void:
    var dir := DirAccess.open(folder)
    if dir == null:
        return
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if file_name.ends_with(".tres"):
            var item: ItemData = load(folder + file_name)
            if item and item.id != "":
                _items[item.id] = item
        file_name = dir.get_next()


func get_item(id: String) -> ItemData:
    return _items.get(id, null)


# ── Serialize ────────────────────────────────────────────────────────────────

func serialize_inventory(inventory: Inventory) -> Array:
    var data: Array = []
    for slot in inventory.slots:
        if slot.is_empty():
            data.append(null)
        else:
            data.append({"id": slot.item.id, "qty": slot.quantity})
    return data


# ── Deserialize ──────────────────────────────────────────────────────────────

func deserialize_inventory(inventory: Inventory, data: Array) -> void:
    for i in mini(data.size(), inventory.slots.size()):
        var entry = data[i]
        if entry == null:
            inventory.slots[i] = InventorySlot.new()
        else:
            var item: ItemData = get_item(entry["id"])
            if item == null:
                push_error("ItemRegistry: unknown item id '%s'" % entry["id"])
                inventory.slots[i] = InventorySlot.new()
                continue
            var slot          := InventorySlot.new()
            slot.item         = item
            slot.quantity     = entry["qty"]
            inventory.slots[i] = slot
    inventory.inventory_changed.emit()
```

**Usage inside a save system:**

```gdscript
# In SaveManager.save_game():
data["inventory"] = ItemRegistry.serialize_inventory(player.inventory)

# In SaveManager.load_game():
ItemRegistry.deserialize_inventory(player.inventory, data["inventory"])
```



---
