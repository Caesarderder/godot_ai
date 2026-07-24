extends Node

const SaveManagerCore := preload("res://game/scripts/persistence/save_manager.gd")

var core: RefCounted = SaveManagerCore.new()


func save_state(state: RefCounted) -> bool:
	return core.save_state(state)


func load_state() -> Dictionary:
	return core.load_state()
