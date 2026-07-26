class_name MusicDirector
extends Node

const SILENT: StringName = &"silent"
const BASE: StringName = &"base"
const BATTLE: StringName = &"battle"
const BOSS: StringName = &"boss"
const VALID_STATES: Array[StringName] = [SILENT, BASE, BATTLE, BOSS]
const FADE_SECONDS := 0.8
const MIN_VOLUME_DB := -60.0

const BASE_MUSIC := preload("res://assets/audio/music/base_factory.ogg")
const BATTLE_MUSIC := preload("res://assets/audio/music/battle_robotic.ogg")

@onready var _player_a: AudioStreamPlayer = %MusicA
@onready var _player_b: AudioStreamPlayer = %MusicB

var _active_player: AudioStreamPlayer
var _transition: Tween
var _state: StringName = SILENT
var _music_linear := 0.55
var _runtime_active := true


func _ready() -> void:
	_active_player = _player_a
	_apply_runtime_pause()


func request_state(next_state: StringName, immediate: bool = false) -> void:
	if not VALID_STATES.has(next_state):
		push_warning("Unknown music state: %s" % next_state)
		return
	if next_state == _state and (
		next_state == SILENT
		or (_active_player.playing and _active_player.stream == _stream_for(next_state))
	):
		return
	_state = next_state
	if next_state == SILENT:
		_fade_out(immediate)
		return
	_crossfade_to(_stream_for(next_state), _target_volume_db(next_state), immediate)


func set_music_volume(percent: Variant) -> void:
	_music_linear = clampf(float(percent) / 100.0, 0.0, 1.0)
	if _state == SILENT or not is_instance_valid(_active_player):
		return
	var target := _target_volume_db(_state)
	if _transition != null and _transition.is_valid():
		_transition.kill()
		_transition = null
	_active_player.volume_db = target


func set_runtime_active(active: bool) -> void:
	_runtime_active = active
	_apply_runtime_pause()


func current_state() -> StringName:
	return _state


func active_track_count() -> int:
	var count := 0
	for player in [_player_a, _player_b]:
		if player.playing and not player.stream_paused:
			count += 1
	return count


func shutdown() -> void:
	_cancel_transition()
	for player in [_player_a, _player_b]:
		player.stop()
		player.stream = null
	_state = SILENT


func _crossfade_to(stream: AudioStream, target_db: float, immediate: bool) -> void:
	_cancel_transition()
	var previous := _active_player
	var next := _player_b if previous == _player_a else _player_a
	next.stop()
	next.stream = stream
	next.volume_db = target_db if immediate else MIN_VOLUME_DB
	next.play()
	next.stream_paused = not _runtime_active
	_active_player = next
	if immediate:
		previous.stop()
		previous.stream = null
		return
	_transition = create_tween().set_parallel(true)
	_transition.tween_property(previous, "volume_db", MIN_VOLUME_DB, FADE_SECONDS)
	_transition.tween_property(next, "volume_db", target_db, FADE_SECONDS)
	_transition.chain().tween_callback(_finish_transition.bind(previous))


func _fade_out(immediate: bool) -> void:
	_cancel_transition()
	if immediate:
		_finish_transition(_active_player)
		return
	_transition = create_tween()
	_transition.tween_property(_active_player, "volume_db", MIN_VOLUME_DB, FADE_SECONDS)
	_transition.tween_callback(_finish_transition.bind(_active_player))


func _finish_transition(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	_transition = null


func _cancel_transition() -> void:
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_transition = null


func _apply_runtime_pause() -> void:
	if not is_node_ready():
		return
	for player in [_player_a, _player_b]:
		player.stream_paused = not _runtime_active


func _stream_for(music_state: StringName) -> AudioStream:
	return BASE_MUSIC if music_state == BASE else BATTLE_MUSIC


func _target_volume_db(music_state: StringName) -> float:
	if _music_linear <= 0.0001:
		return MIN_VOLUME_DB
	var mix_db := -12.0
	if music_state == BATTLE:
		mix_db = -8.0
	elif music_state == BOSS:
		mix_db = -6.0
	return maxf(MIN_VOLUME_DB, mix_db + linear_to_db(_music_linear))
