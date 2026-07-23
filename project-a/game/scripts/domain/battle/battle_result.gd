class_name BattleResult
extends RefCounted

var winner: int:
	get: return _winner
var outcome: String:
	get: return _outcome
var ticks: int:
	get: return _ticks
var end_state: Array:
	get: return _end_state.duplicate(true)
var events: Array:
	get: return _events.duplicate(true)
var reward_roll: int:
	get: return _reward_roll
var digest: String:
	get: return _digest
var result_id: String:
	get: return _result_id

var _winner: int
var _outcome: String
var _ticks: int
var _end_state: Array
var _events: Array
var _reward_roll: int
var _digest: String
var _result_id: String


func _init(
	result_winner: int, tick_count: int, units: Array, battle_events: Array, result_reward_roll: int
) -> void:
	_winner = result_winner
	_outcome = "draw" if result_winner < 0 else ("victory" if result_winner == 0 else "defeat")
	_ticks = tick_count
	_end_state = units.duplicate(true)
	_events = battle_events.duplicate(true)
	_reward_roll = result_reward_roll
	_digest = _sha256(_canonical([_winner, _outcome, _ticks, _end_state, _events, _reward_roll]))
	_result_id = "battle-result-v1:%s" % _digest


static func _sha256(text: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(text.to_utf8_buffer())
	return context.finish().hex_encode()


static func _canonical(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_INT:
			return str(value)
		TYPE_FLOAT:
			assert(value == floor(value), "BattleResult rejects non-integer floats")
			return str(int(value))
		TYPE_STRING:
			return JSON.stringify(value)
		TYPE_ARRAY:
			var items: PackedStringArray = []
			for item in value:
				items.append(_canonical(item))
			return "[" + ",".join(items) + "]"
		TYPE_DICTIONARY:
			var keys: Array = value.keys()
			for key in keys:
				assert(typeof(key) == TYPE_STRING, "BattleResult dictionary keys must be strings")
			keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
			var pairs: PackedStringArray = []
			for key in keys:
				pairs.append(JSON.stringify(str(key)) + ":" + _canonical(value[key]))
			return "{" + ",".join(pairs) + "}"
		_:
			assert(false, "BattleResult only accepts serializable primitives")
			return ""
