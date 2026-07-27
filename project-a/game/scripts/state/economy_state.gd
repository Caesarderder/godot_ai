class_name EconomyState
extends RefCounted

const RESOURCE_KEYS: Array[String] = ["toilet_coins", "toilet_gems", "gold", "recruit_tickets", "xp_books", "forge_stones", "industrial_tech", "skill_chips", "hero_shards"]

var toilet_coins: int = 0
var toilet_gems: int = 0
var gold: int = 0
var recruit_tickets: int = 0
var xp_books: int = 0
var forge_stones: int = 0
var industrial_tech: int = 0
var skill_chips: int = 0
var hero_shards: int = 0


static func create_starting() -> EconomyState:
	var economy := EconomyState.new()
	economy.toilet_coins = 250
	economy.recruit_tickets = 0
	# Schema v9 keeps only the four active ledgers non-zero. Legacy fields remain
	# serialized so older call sites can be retired without corrupting saves.
	economy.toilet_gems = 0
	economy.gold = 0
	economy.xp_books = 0
	economy.forge_stones = 0
	economy.industrial_tech = 0
	economy.skill_chips = 0
	economy.hero_shards = 0
	return economy


func deep_clone() -> EconomyState:
	return EconomyState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {
		"toilet_coins": toilet_coins,
		"toilet_gems": toilet_gems,
		"gold": gold,
		"recruit_tickets": recruit_tickets,
		"xp_books": xp_books,
		"forge_stones": forge_stones,
		"industrial_tech": industrial_tech,
		"skill_chips": skill_chips,
		"hero_shards": hero_shards,
	}


static func from_dict(data: Dictionary) -> EconomyState:
	var economy := EconomyState.new()
	economy.toilet_coins = int(data.get("toilet_coins", data.get("gold", 0)))
	economy.toilet_gems = int(data.get("toilet_gems", 0))
	economy.gold = int(data.get("gold", 0))
	economy.recruit_tickets = int(data.get("recruit_tickets", 0))
	economy.xp_books = int(data.get("xp_books", 0))
	economy.forge_stones = int(data.get("forge_stones", 0))
	economy.industrial_tech = int(data.get("industrial_tech", 0))
	economy.skill_chips = int(data.get("skill_chips", 0))
	economy.hero_shards = int(data.get("hero_shards", 0))
	return economy


func grant(resources: Dictionary) -> void:
	if resources.has("toilet_coins"):
		toilet_coins += int(resources["toilet_coins"])
	if resources.has("toilet_gems"):
		toilet_gems += int(resources["toilet_gems"])
	if resources.has("gold"):
		gold += int(resources["gold"])
	if resources.has("recruit_tickets"):
		recruit_tickets += int(resources["recruit_tickets"])
	if resources.has("xp_books"):
		xp_books += int(resources["xp_books"])
	if resources.has("forge_stones"):
		forge_stones += int(resources["forge_stones"])
	if resources.has("industrial_tech"):
		industrial_tech += int(resources["industrial_tech"])
	if resources.has("skill_chips"):
		skill_chips += int(resources["skill_chips"])
	if resources.has("hero_shards"):
		hero_shards += int(resources["hero_shards"])


func validate() -> Array[String]:
	var errors: Array[String] = []
	if toilet_coins < 0:
		errors.append("toilet_coins must not be negative")
	if toilet_gems < 0:
		errors.append("toilet_gems must not be negative")
	if gold < 0:
		errors.append("gold must not be negative")
	if recruit_tickets < 0:
		errors.append("recruit_tickets must not be negative")
	if xp_books < 0:
		errors.append("xp_books must not be negative")
	if forge_stones < 0:
		errors.append("forge_stones must not be negative")
	if industrial_tech < 0:
		errors.append("industrial_tech must not be negative")
	if skill_chips < 0:
		errors.append("skill_chips must not be negative")
	if hero_shards < 0:
		errors.append("hero_shards must not be negative")
	return errors
