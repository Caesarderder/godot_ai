class_name EconomyState
extends RefCounted

const RESOURCE_KEYS: Array[String] = ["gold", "recruit_tickets", "xp_books", "forge_stones"]

var gold: int = 0
var recruit_tickets: int = 0
var xp_books: int = 0
var forge_stones: int = 0


static func create_starting() -> EconomyState:
	var economy := EconomyState.new()
	economy.gold = 250
	economy.recruit_tickets = 0
	economy.xp_books = 2
	return economy


func deep_clone() -> EconomyState:
	return EconomyState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"recruit_tickets": recruit_tickets,
		"xp_books": xp_books,
		"forge_stones": forge_stones,
	}


static func from_dict(data: Dictionary) -> EconomyState:
	var economy := EconomyState.new()
	economy.gold = int(data.get("gold", 0))
	economy.recruit_tickets = int(data.get("recruit_tickets", 0))
	economy.xp_books = int(data.get("xp_books", 0))
	economy.forge_stones = int(data.get("forge_stones", 0))
	return economy


func grant(resources: Dictionary) -> void:
	if resources.has("gold"):
		gold += int(resources["gold"])
	if resources.has("recruit_tickets"):
		recruit_tickets += int(resources["recruit_tickets"])
	if resources.has("xp_books"):
		xp_books += int(resources["xp_books"])
	if resources.has("forge_stones"):
		forge_stones += int(resources["forge_stones"])


func validate() -> Array[String]:
	var errors: Array[String] = []
	if gold < 0:
		errors.append("gold must not be negative")
	if recruit_tickets < 0:
		errors.append("recruit_tickets must not be negative")
	if xp_books < 0:
		errors.append("xp_books must not be negative")
	if forge_stones < 0:
		errors.append("forge_stones must not be negative")
	return errors
