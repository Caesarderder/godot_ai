class_name AudioDirector
extends Node

const BUS_NAME: StringName = &"Master"
const MIX_RATE: int = 22050
const MAX_PLAYERS: int = 10

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _cursor: int = 0


func _ready() -> void:
	_build_streams()
	for index in MAX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.name = "GeneratedSfx_%02d" % index
		player.bus = BUS_NAME
		player.volume_db = -8.0
		add_child(player)
		_players.append(player)


func play_cue(cue_id: StringName, volume_db: float = -8.0, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = _streams.get(cue_id)
	if stream == null:
		return
	var player := _next_player()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _next_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var player := _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	return player


func _build_streams() -> void:
	_streams[&"warning"] = _tone_stream(180.0, 0.16, 0.55, 0.20)
	_streams[&"skill"] = _tone_stream(640.0, 0.13, 0.38, 0.45)
	_streams[&"heal"] = _tone_stream(520.0, 0.20, 0.30, 0.65)
	_streams[&"shield"] = _tone_stream(260.0, 0.18, 0.42, 0.30)
	_streams[&"hit"] = _noise_burst(0.07, 0.24, 0.18)
	_streams[&"explosion"] = _noise_burst(0.32, 0.82, 0.08)
	_streams[&"collapse"] = _noise_burst(0.52, 0.92, 0.03)
	_streams[&"cannon_suppressed"] = _suppression_cut_stream()


func _tone_stream(frequency: float, duration: float, volume: float, decay: float) -> AudioStreamWAV:
	var frames := maxi(1, int(MIX_RATE * duration))
	var data := PackedByteArray()
	data.resize(frames * 2)
	for index in frames:
		var t := float(index) / float(MIX_RATE)
		var envelope := maxf(0.0, 1.0 - pow(t / duration, 1.0 + decay * 3.0))
		var wobble := sin(TAU * frequency * 0.51 * t) * 0.28
		var sample := sin(TAU * frequency * t + wobble) * envelope * volume
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wav(data)


func _noise_burst(duration: float, volume: float, attack: float) -> AudioStreamWAV:
	var frames := maxi(1, int(MIX_RATE * duration))
	var data := PackedByteArray()
	data.resize(frames * 2)
	var seed := 12491
	for index in frames:
		seed = int((seed * 1103515245 + 12345) & 0x7fffffff)
		var random_value := (float(seed % 2000) / 1000.0) - 1.0
		var t := float(index) / float(MIX_RATE)
		var attack_amount := clampf(t / maxf(0.001, attack), 0.0, 1.0)
		var decay_amount := maxf(0.0, 1.0 - pow(t / duration, 0.42))
		var low_rumble := sin(TAU * 54.0 * t) * 0.45
		var sample := (random_value * 0.65 + low_rumble) * attack_amount * decay_amount * volume
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wav(data)


func _suppression_cut_stream() -> AudioStreamWAV:
	var duration := 0.24
	var frames := maxi(1, int(MIX_RATE * duration))
	var data := PackedByteArray()
	data.resize(frames * 2)
	var seed := 76123
	for index in frames:
		seed = int((seed * 1103515245 + 12345) & 0x7fffffff)
		var random_value := (float(seed % 2000) / 1000.0) - 1.0
		var t := float(index) / float(MIX_RATE)
		var normalized := t / duration
		var snap_envelope := maxf(0.0, 1.0 - t / 0.055)
		var drain_envelope := maxf(0.0, 1.0 - pow(normalized, 0.72))
		var drain_frequency := lerpf(920.0, 210.0, clampf(normalized * 1.25, 0.0, 1.0))
		var bright_snap := (
			sin(TAU * 1860.0 * t)
			+ sin(TAU * 2420.0 * t) * 0.55
		) * snap_envelope * 0.30
		var power_drain := sin(TAU * drain_frequency * t) * drain_envelope * 0.24
		var short_hiss := random_value * maxf(0.0, 1.0 - normalized) * 0.12
		var gate := 0.62 if fmod(t, 0.021) < 0.014 else 0.28
		var sample := (bright_snap + power_drain + short_hiss) * gate
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wav(data)


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
