# Equipment Extension

Reference for `skills/inventory-system/SKILL.md` — equipment slot system (paperdoll), `EquipmentSlotType` enum, GDScript implementations.

> ← Back to [SKILL.md](../SKILL.md)

---
## 5. Equipment Extension

Extend `Inventory` with a dedicated equipment layer. Equipment slots are keyed by a `SlotType` enum, and stat bonuses are aggregated on demand.

### GDScript

```gdscript
# equipment.gd
class_name Equipment
extends Node

signal equipment_changed(slot: SlotType, item: ItemData)

enum SlotType {
    HEAD,
    CHEST,
    LEGS,
    HANDS,
    FEET,
    WEAPON,
    OFF_HAND,
    ACCESSORY,
}

# Maps SlotType → the ItemData currently equipped in that slot (null = empty)
var equipment_slots: Dictionary = {}


func _ready() -> void:
    for slot_type in SlotType.values():
        equipment_slots[slot_type] = null


func equip(item: ItemData, slot: SlotType) -> ItemData:
    assert(item.item_type == ItemData.ItemType.EQUIPMENT,
        "equip: '%s' is not an EQUIPMENT item" % item.name)
    var previous: ItemData = equipment_slots[slot]
    equipment_slots[slot] = item
    equipment_changed.emit(slot, item)
    return previous  # caller can return this to the inventory


func unequip(slot: SlotType) -> ItemData:
    var item: ItemData = equipment_slots[slot]
    equipment_slots[slot] = null
    if item != null:
        equipment_changed.emit(slot, null)
    return item


func get_equipped(slot: SlotType) -> ItemData:
    return equipment_slots.get(slot, null)


# Aggregate a named numeric stat from all equipped items.
# Each ItemData can expose stat bonuses via a Dictionary property named "stats".
# e.g. item.stats = { "attack": 10, "defense": 5 }
func get_total_stat(stat_name: String) -> float:
    var total := 0.0
    for item: ItemData in equipment_slots.values():
        if item == null:
            continue
        if item.get("stats") is Dictionary:
            total += float(item.stats.get(stat_name, 0))
    return total
```



---
