class_name HeroArchetypes
extends RefCounted

const ROSTER := {
	"aerion": {"name": "Aerion", "role": "Vanguard", "attack": 61, "health": 720, "signature": "Solar Guard"},
	"vesper": {"name": "Vesper", "role": "Skirmisher", "attack": 68, "health": 610, "signature": "Rift Step"},
	"mira": {"name": "Mira", "role": "Channeler", "attack": 49, "health": 540, "signature": "Comet Array"},
	"orun": {"name": "Orun", "role": "Warden", "attack": 52, "health": 790, "signature": "Anchor Field"},
	"sable": {"name": "Sable", "role": "Marksman", "attack": 71, "health": 560, "signature": "Prism Shot"},
}

static func has(hero_id: String) -> bool:
	return ROSTER.has(hero_id)

static func get_hero(hero_id: String) -> Dictionary:
	return ROSTER.get(hero_id, {}).duplicate(true)
