extends Node

signal save_requested(reason: StringName)

const SAVE_PATH := "user://savegame.json"
const BACKUP_PATH := "user://savegame.backup.json"


func request_save(reason: StringName) -> void:
	save_requested.emit(reason)
