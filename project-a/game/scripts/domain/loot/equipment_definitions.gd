class_name EquipmentDefinitions
extends RefCounted

const SLOTS: Array[String] = ["weapon", "armor", "accessory"]
const QUALITIES: Array[String] = ["white", "green", "blue", "purple"]

const TEMPLATE_DATA: Dictionary = {
	"guardian_blade": {"slot": "weapon", "class_tags": ["guardian"], "stat": "str"},
	"fighter_axe": {"slot": "weapon", "class_tags": ["fighter"], "stat": "str"},
	"ranger_bow": {"slot": "weapon", "class_tags": ["ranger"], "stat": "agi"},
	"arcanist_staff": {"slot": "weapon", "class_tags": ["arcanist"], "stat": "int"},
	"guardian_plate": {"slot": "armor", "class_tags": ["guardian"], "stat": "vig"},
	"fighter_mail": {"slot": "armor", "class_tags": ["fighter"], "stat": "vig"},
	"ranger_leathers": {"slot": "armor", "class_tags": ["ranger"], "stat": "agi"},
	"arcanist_robes": {"slot": "armor", "class_tags": ["arcanist"], "stat": "int"},
	"oath_ring": {"slot": "accessory", "class_tags": ["guardian", "fighter"], "stat": "vig"},
	"hawk_charm": {"slot": "accessory", "class_tags": ["ranger"], "stat": "agi"},
	"ember_focus": {"slot": "accessory", "class_tags": ["arcanist"], "stat": "int"},
	"traveler_medal": {
		"slot": "accessory",
		"class_tags": ["guardian", "fighter", "ranger", "arcanist"],
		"stat": "str",
	},
}

const AFFIX_DATA: Dictionary = {
	"strength": {"stat": "str", "value": 4},
	"vitality": {"stat": "vig", "value": 4},
	"agility": {"stat": "agi", "value": 4},
	"focus": {"stat": "int", "value": 4},
	"guard": {"stat": "armor", "value": 3},
	"haste": {"stat": "speed", "value": 3},
	"precision": {"stat": "crit", "value": 2},
	"resolve": {"stat": "resist", "value": 2},
	"fortune": {"stat": "gold_bonus", "value": 2},
	"training": {"stat": "xp_bonus", "value": 2},
}


static func templates() -> Dictionary:
	return TEMPLATE_DATA.duplicate(true)


static func affixes() -> Dictionary:
	return AFFIX_DATA.duplicate(true)


static func quality_rank(quality: String) -> int:
	return QUALITIES.find(quality)


static func template_slot(template_id: String) -> String:
	var template: Dictionary = TEMPLATE_DATA.get(template_id, {})
	return String(template.get("slot", ""))
