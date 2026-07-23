class_name DeterministicBattleRng
extends RefCounted

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	_rng.seed = seed_value


func next_int(minimum: int, maximum: int) -> int:
	assert(minimum <= maximum)
	return _rng.randi_range(minimum, maximum)


func choose_index(count: int) -> int:
	assert(count > 0)
	return next_int(0, count - 1)
