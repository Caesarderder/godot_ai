extends Node

const SaveManagerCore := preload("res://game/scripts/persistence/save_manager.gd")

var core: RefCounted = SaveManagerCore.new()


func configure_save_path(path: String) -> void:
	core = SaveManagerCore.new(path)


func save_state(state: RefCounted) -> bool:
	return core.save_state(state)


func load_state() -> Dictionary:
	return core.load_state()


func export_state(state: RefCounted) -> Dictionary:
	return core.export_state(state)


func parse_import_text(text: String) -> Dictionary:
	return core.parse_import_text(text)


func publish_imported_state(state: RefCounted) -> Dictionary:
	return core.publish_imported_state(state)


func delete_local_save() -> Dictionary:
	return core.delete_local_save()
