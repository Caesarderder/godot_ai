extends SceneTree

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_new_save_contract()
	_test_v9_five_stat_migration_is_exact_and_once_only()
	_test_v8_resource_migration_is_exact_and_once_only()
	_test_v8_high_balance_migration_preserves_exact_value()
	_test_v8_migration_rejects_invalid_legacy_balances()
	_test_v8_migration_rejects_unknown_resource_ids()
	_test_v9_rejects_unconsolidated_legacy_fields()
	_test_v9_rejects_forged_capacity()
	_test_capacity_uses_all_active_resource_line_levels()
	if failures.is_empty():
		print("SCHEMA_V9_PERSISTENCE_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SCHEMA_V9_PERSISTENCE_TESTS_FAIL: %d" % failures.size())
	quit(1)


func _test_new_save_contract() -> void:
	var state := GameStateScript.create_new(9001, 100, false)
	var encoded := SaveCodecScript.encode(state)
	_eq(encoded["schema_version"], 11, "new saves use schema v11")
	_eq(encoded["meta_progression"]["hero_fragments"], {}, "new saves start with an empty archetype-fragment ledger")
	_eq(
		encoded["factory"]["materials"],
		{"porcelain": 112, "parts": 0, "sludge": 0},
		"new saves start with 112 consolidated industrial materials"
	)
	for key in ["toilet_gems", "gold", "xp_books", "forge_stones", "industrial_tech", "skill_chips"]:
		_eq(encoded["economy"][key], 0, "new saves clear legacy economy field %s" % key)
	_eq(encoded["factory"]["capacities"]["porcelain"], 2160, "new save capacity has the minimum")
	_eq(encoded["factory"]["capacities"]["parts"], 2160, "parts compatibility capacity stays positive")
	_eq(encoded["factory"]["capacities"]["sludge"], 2160, "sludge compatibility capacity stays positive")


func _test_v8_resource_migration_is_exact_and_once_only() -> void:
	var legacy := GameStateScript.create_new(9002, 100, true).to_dict()
	legacy["schema_version"] = 8
	legacy["economy"]["toilet_coins"] = 321
	legacy["economy"]["toilet_gems"] = 27
	legacy["economy"]["recruit_tickets"] = 1
	legacy["economy"]["hero_shards"] = 3
	legacy["economy"]["industrial_tech"] = 5
	legacy["economy"]["skill_chips"] = 2
	legacy["economy"]["gold"] = 99
	legacy["economy"]["xp_books"] = 7
	legacy["economy"]["forge_stones"] = 6
	legacy["factory"]["materials"] = {"porcelain": 10, "parts": 7, "sludge": 6}
	legacy["factory"]["blueprint_data"] = {"ordinary.assault": 2, "heavy.armored": 5}
	legacy["meta_progression"]["hero_data"] = {"ordinary.assault": 4, "heavy.armored": 6}

	var decoded := SaveCodecScript.decode(legacy)
	_ok(bool(decoded.get("ok", false)), "v8 save decodes through the v9 migration")
	if not bool(decoded.get("ok", false)):
		return
	var migrated: RefCounted = decoded["state"]
	_eq(migrated.economy.toilet_coins, 321, "coins reuse toilet_coins without conversion")
	_eq(migrated.economy.recruit_tickets, 3, "twenty-seven gems grant two tickets and discard the remainder")
	_eq(migrated.economy.hero_shards, 28, "legion data consolidates shards, chips, blueprint data, and hero data")
	_eq(migrated.factory.materials, {"porcelain": 32, "parts": 0, "sludge": 0}, "industrial material conversion uses the exact weighted formula")
	_eq(migrated.factory.blueprint_data, {}, "blueprint data is cleared after consolidation")
	_eq(migrated.meta_progression.hero_data, {}, "hero data is cleared after consolidation")
	for key in ["toilet_gems", "gold", "xp_books", "forge_stones", "industrial_tech", "skill_chips"]:
		_eq(migrated.economy.get(key), 0, "migration clears legacy economy field %s" % key)

	var encoded_v9 := SaveCodecScript.encode(migrated)
	_eq(encoded_v9["schema_version"], 11, "migrated state rewrites as schema v11")
	var decoded_again := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(migrated))
	_ok(bool(decoded_again.get("ok", false)), "rewritten v9 JSON save decodes")
	if bool(decoded_again.get("ok", false)):
		var second: RefCounted = decoded_again["state"]
		_eq(second.economy.recruit_tickets, 3, "v9 reload does not convert tickets twice")
		_eq(second.economy.hero_shards, 28, "v9 reload does not consolidate legion data twice")
		_eq(second.factory.materials["porcelain"], 32, "v9 reload does not consolidate industrial materials twice")


func _test_v9_five_stat_migration_is_exact_and_once_only() -> void:
	var legacy := GameStateScript.create_new(9010, 100, true).to_dict()
	legacy["schema_version"] = 9
	var hero := legacy["roster"][0] as Dictionary
	hero["class_id"] = "guardian"
	hero["star"] = 3
	hero["base_stats"] = {"vig": 14, "str": 7, "agi": 6, "int": 4}
	hero["stat_remainders"] = {"vig": 999, "str": 888, "agi": 777, "int": 666}
	var decoded := SaveCodecScript.decode(legacy)
	_ok(bool(decoded.get("ok", false)), "v9 save decodes through the v10 five-stat migration")
	if not bool(decoded.get("ok", false)):
		return
	var migrated_hero: RefCounted = decoded["state"].roster[0]
	_eq(
		migrated_hero.base_stats,
		{"hp": 190, "attack": 21, "defense": 40, "speed_milli": 84000, "crit_bp": 800},
		"v9 legacy attributes convert to unstarred five-stat values"
	)
	_eq(
		migrated_hero.stat_remainders,
		{"hp": 0, "attack": 0, "defense": 0, "speed_milli": 0, "crit_bp": 0},
		"v9 attribute remainders are cleared during the one-time conversion"
	)
	var decoded_again := SaveCodecScript.from_json_text(
		SaveCodecScript.to_json_text(decoded["state"])
	)
	_ok(bool(decoded_again.get("ok", false)), "rewritten v10 five-stat save decodes")
	if bool(decoded_again.get("ok", false)):
		_eq(
			decoded_again["state"].roster[0].base_stats,
			migrated_hero.base_stats,
			"v10 reload does not convert or multiply five-stat values twice"
		)


func _test_capacity_uses_all_active_resource_line_levels() -> void:
	var factory := FactoryStateScript.create_starting(false)
	_eq(factory.capacities["porcelain"], 2160, "zero active lines use the minimum capacity")
	factory.facilities["porcelain_plant"] = 2
	factory.facilities["parts_workshop"] = 1
	factory.facilities["energy_station"] = 3
	factory.refresh_capacities()
	_eq(factory.capacities["porcelain"], 12960, "capacity sums all active resource line levels")
	_ok(int(factory.capacities["parts"]) > 0, "parts compatibility capacity remains positive")
	_ok(int(factory.capacities["sludge"]) > 0, "sludge compatibility capacity remains positive")


func _test_v8_high_balance_migration_preserves_exact_value() -> void:
	var legacy := GameStateScript.create_new(9006, 100, true).to_dict()
	legacy["schema_version"] = 8
	for facility_id in ["porcelain_plant", "parts_workshop", "energy_station"]:
		legacy["factory"]["facilities"][facility_id] = 3
	legacy["factory"]["materials"] = {"porcelain": 15552, "parts": 7776, "sludge": 10368}
	legacy["economy"]["industrial_tech"] = 5
	var decoded := SaveCodecScript.decode(legacy)
	_ok(bool(decoded.get("ok", false)), "valid high-balance v8 save migrates without rejection")
	if not bool(decoded.get("ok", false)):
		return
	var migrated: RefCounted = decoded["state"]
	_eq(migrated.factory.materials["porcelain"], 23343, "high industrial balance preserves the exact weighted conversion")
	_eq(migrated.factory.capacities["porcelain"], 19440, "high balance does not forge a larger derived capacity")
	migrated.factory.grant({"porcelain": 1})
	_eq(migrated.factory.materials["porcelain"], 23343, "claiming while over capacity does not truncate migrated balance")
	var roundtrip := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(migrated))
	_ok(bool(roundtrip.get("ok", false)), "over-cap migrated balance survives the v9 JSON round-trip")


func _test_v8_migration_rejects_invalid_legacy_balances() -> void:
	var string_balance := GameStateScript.create_new(9003, 100, true).to_dict()
	string_balance["schema_version"] = 8
	string_balance["economy"]["gold"] = "99"
	_ok(not bool(SaveCodecScript.decode(string_balance).get("ok", false)), "v8 migration rejects stringified legacy balances")

	var negative_balance := GameStateScript.create_new(9004, 100, true).to_dict()
	negative_balance["schema_version"] = 8
	negative_balance["economy"]["gold"] = -1
	_ok(not bool(SaveCodecScript.decode(negative_balance).get("ok", false)), "v8 migration rejects negative legacy balances")


func _test_v8_migration_rejects_unknown_resource_ids() -> void:
	var invalid_blueprint := GameStateScript.create_new(9007, 100, true).to_dict()
	invalid_blueprint["schema_version"] = 8
	invalid_blueprint["factory"]["blueprint_data"] = {"not.a.recipe": 100}
	_ok(not bool(SaveCodecScript.decode(invalid_blueprint).get("ok", false)), "v8 migration rejects unknown blueprint data IDs")

	var invalid_archetype := GameStateScript.create_new(9008, 100, true).to_dict()
	invalid_archetype["schema_version"] = 8
	invalid_archetype["meta_progression"]["hero_data"] = {"not_an_archetype": 100}
	_ok(not bool(SaveCodecScript.decode(invalid_archetype).get("ok", false)), "v8 migration rejects unknown hero data IDs")


func _test_v9_rejects_unconsolidated_legacy_fields() -> void:
	var invalid_v9 := SaveCodecScript.encode(GameStateScript.create_new(9005, 100, true))
	invalid_v9["economy"]["skill_chips"] = 1
	_ok(not bool(SaveCodecScript.decode(invalid_v9).get("ok", false)), "v9 rejects non-zero legacy balances")


func _test_v9_rejects_forged_capacity() -> void:
	var invalid_v9 := SaveCodecScript.encode(GameStateScript.create_new(9009, 100, true))
	invalid_v9["factory"]["capacities"]["porcelain"] = 999999
	_ok(not bool(SaveCodecScript.decode(invalid_v9).get("ok", false)), "v9 rejects capacity values not derived from active line levels")


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
