class_name AudioDirector
extends Node

const BUS_NAME: StringName = &"Master"
const MAX_PLAYERS: int = 8
const MIN_REPEAT_INTERVAL_MSEC: int = 45

const UI_CLICK := preload("res://assets/audio/ui/click.ogg")
const UI_SELECT := preload("res://assets/audio/ui/select.ogg")
const IMPACT_LIGHT := preload("res://assets/audio/sfx/impact_light.ogg")
const IMPACT_HEAVY := preload("res://assets/audio/sfx/impact_heavy.ogg")
const VICTORY_JINGLE := preload("res://assets/audio/jingles/victory.ogg")
const DEFEAT_JINGLE := preload("res://assets/audio/jingles/defeat.ogg")

const STREAMS := {
	&"ui_click": UI_CLICK,
	&"ui_select": UI_SELECT,
	&"build": IMPACT_HEAVY,
	&"success": UI_SELECT,
	&"error": DEFEAT_JINGLE,
	&"victory": VICTORY_JINGLE,
	&"defeat": DEFEAT_JINGLE,
	&"retreat": UI_SELECT,
	&"warning": UI_SELECT,
	&"skill": UI_SELECT,
	&"heal": UI_SELECT,
	&"shield": IMPACT_LIGHT,
	&"hit": IMPACT_LIGHT,
	&"explosion": IMPACT_HEAVY,
	&"collapse": IMPACT_HEAVY,
	&"cannon_suppressed": IMPACT_HEAVY,
	&"cannon_guard_counter": IMPACT_HEAVY,
}

var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var _last_played_msec: Dictionary = {}
var playback_enabled: bool = true


func _ready() -> void:
	for index in MAX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.name = "Sfx_%02d" % index
		player.bus = BUS_NAME
		player.volume_db = -8.0
		player.max_polyphony = 1
		add_child(player)
		_players.append(player)


func _exit_tree() -> void:
	for player in _players:
		if not is_instance_valid(player):
			continue
		player.stop()
		player.stream = null
	_players.clear()
	_last_played_msec.clear()


func has_cue(cue_id: StringName) -> bool:
	return STREAMS.has(cue_id)


func set_playback_enabled(enabled: bool) -> void:
	playback_enabled = enabled
	if not playback_enabled:
		stop_all()


func play_cue(cue_id: StringName, volume_db: float = -8.0, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = STREAMS.get(cue_id)
	if not playback_enabled or stream == null or _players.is_empty():
		return
	var now_msec := Time.get_ticks_msec()
	var last_msec := int(_last_played_msec.get(cue_id, -MIN_REPEAT_INTERVAL_MSEC))
	if now_msec - last_msec < MIN_REPEAT_INTERVAL_MSEC:
		return
	_last_played_msec[cue_id] = now_msec
	var player := _next_player()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.play()


func stop_all() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.stop()


func active_voice_count() -> int:
	var count := 0
	for player in _players:
		if is_instance_valid(player) and player.playing:
			count += 1
	return count


func _next_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var player := _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	return player
