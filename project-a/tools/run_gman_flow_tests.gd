extends SceneTree

# 文件名为旧 CI 入口保留；内容负责保护永久 G-Man 与移除三合一/抽取入口的新合同。
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const CommandClassRegistryScript := preload("res://game/scripts/commands/command_class_registry.gd")

var failures: Array[String] = []


func _init() -> void:
	var state: RefCounted = GameStateScript.create_new(20260726, 100)
	_check(int(state.schema_version) == 10, "new campaign uses schema v10")
	_check(String(state.roster[0].archetype_id) == "gman", "starter legion is led by permanent G-Man")
	_check(state.roster.size() == 1, "new campaign starts with G-Man as its only unlocked hero")
	_check(state.factory.blueprints.size() == 4, "hidden compatibility data preserves four baseline model blueprints")
	_check(int(state.economy.toilet_coins) == 250 and int(state.economy.toilet_gems) == 0, "new campaign exposes no premium starting currency")
	_check(state.formation.hero_ids() == state.roster_ids(), "new campaign deploys only G-Man")
	for removed_command in ["recruit_hero", "train_hero", "merge_heroes", "exchange_salvage", "purchase_gold_shop", "start_blueprint_research"]:
		_check(not CommandClassRegistryScript.has_command(removed_command), "%s remains removed from command authority" % removed_command)
	var executor: RefCounted = CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var old_merge: Dictionary = executor.execute({
		"type": "merge_heroes",
		"command_id": "legacy-merge-attempt",
		"business_key": "",
		"expected_revision": 0,
		"payload": {"hero_ids": ["a", "b", "c"]},
	})
	_check(String(old_merge.get("error", "")) == "UNKNOWN_COMMAND", "legacy merge is rejected before mutation")
	if failures.is_empty():
		print("FACTORY FLOW MIGRATION TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FACTORY FLOW MIGRATION TESTS FAIL: %d" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
