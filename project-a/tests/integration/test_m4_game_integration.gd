extends GutTest

const GameScript := preload("res://game/scripts/autoloads/game.gd")
const GameState := preload("res://game/scripts/state/game_state.gd")
const HeroGenerator := preload("res://game/scripts/domain/heroes/hero_generator.gd")
const FixturePath := "res://tests/fixtures/economy/first_30m_v1.json"


class FakeClock:
	extends RefCounted
	func unix_time_seconds() -> int:
		return 1_000
	func monotonic_msec() -> int:
		return 0


class FakeSavePort:
	extends RefCounted
	var saves: Array[Dictionary] = []
	var loaded_state: Dictionary = {}
	func load_state() -> Dictionary:
		if not loaded_state.is_empty():
			return {"ok": true, "state": loaded_state.duplicate(true), "code": "OK"}
		return {"ok": false, "state": {}, "code": "NO_VALID_SAVE"}
	func save_candidate(candidate: Dictionary, saved_at_unix: int) -> Dictionary:
		var installed := candidate.duplicate(true)
		installed.saved_at_unix = saved_at_unix
		saves.append(installed)
		return {"ok": true, "state": installed, "code": "OK"}


class FakeLifecycle:
	extends RefCounted
	func configure(_executor: Object, _clock: Object) -> void:
		pass


class FakeEventBus:
	extends RefCounted
	func emit_domain_event(_event: Dictionary) -> void:
		pass


func _boot_game() -> Node:
	return _boot_game_with_port(FakeSavePort.new()).game


func _boot_game_with_port(save_port: FakeSavePort) -> Dictionary:
	var game: Node = autofree(GameScript.new())
	var result: Dictionary = game.configure_dependencies(
		FakeClock.new(), save_port, FakeEventBus.new(), FakeLifecycle.new()
	)
	assert_true(result.ok, str(result))
	return {"game": game, "save_port": save_port}


func _envelope(game: Node, command_type: String, payload: Dictionary, business_key: String) -> Dictionary:
	var state: Dictionary = game.get_state()
	return {
		"command_id": "%s-%d" % [command_type, int(state.revision) + 1],
		"type": command_type,
		"payload": payload,
		"business_key": business_key,
		"expected_revision": int(state.revision),
		"requested_at": 1_000,
	}


func _command(game: Node, command_type: String, payload: Dictionary, business_key: String) -> Dictionary:
	return game.execute_command(_envelope(game, command_type, payload, business_key))


func test_new_game_hydrates_m4_meta_state() -> void:
	var game := _boot_game()
	var state: Dictionary = game.get_state()
	var fixture: Dictionary = _load_fixture()

	assert_eq(state.roster.size(), fixture.initial.roster_size)
	for hero: Dictionary in state.roster.values():
		assert_true(hero.has("equipment"))
		assert_eq(hero.equipment, {})
	assert_eq(state.formation.slots.size(), 4)
	assert_eq(state.economy.gold, fixture.initial.gold)
	assert_eq(state.economy.recruit_ticket, fixture.initial.recruit_ticket)
	assert_eq(state.economy.xp_book, fixture.initial.xp_book)
	assert_eq(state.economy.forge_stone, fixture.initial.forge_stone)
	assert_eq(state.camp.facilities.size(), 3)
	assert_eq(state.quest.quests.size(), 21)
	assert_eq(state.pity.qualifying_drop_count, 0)
	assert_eq(state.inventory.items.size(), 0)


func test_facility_upgrade_and_quest_claim_are_durable_and_exact_once() -> void:
	var game := _boot_game()
	var settlement: Dictionary = _command(
		game,
		"settle_battle_result",
		{"stage_id": "stage-1-4", "outcome": "win", "first_clear": true},
		"stage:stage-1-4:first-clear",
	)
	assert_true(settlement.ok, str(settlement))
	var claim_envelope := _envelope(
		game, "claim_reward", {"quest_id": "major-01"}, "quest:major-01:claim"
	)
	var claim: Dictionary = game.execute_command(claim_envelope)
	assert_true(claim.ok, str(claim))
	var gold_after_claim := int(game.get_state().economy.gold)
	var replay: Dictionary = game.execute_command(claim_envelope)
	assert_true(replay.ok, str(replay))
	assert_eq(game.get_state().economy.gold, gold_after_claim)

	var upgrade: Dictionary = _command(
		game, "upgrade_facility", {"facility_id": "blacksmith"}, "facility:blacksmith:l2"
	)
	assert_true(upgrade.ok, str(upgrade))
	assert_eq(game.get_state().camp.facilities.blacksmith.level, 2)
	assert_gte(game.get_state().economy.gold, 0)


func test_skipping_task_claim_never_blocks_start_stage() -> void:
	var game := _boot_game()
	var result: Dictionary = _command(
		game,
		"reserve_battle_attempt",
		{"stage_id": "stage-1-4"},
		"battle:stage-1-4:attempt:1",
	)
	assert_true(result.ok, str(result))
	assert_eq(result.result.stage_id, "stage-1-4")


func test_recruit_grows_roster_from_four_to_eight_and_spends_tickets_exact_once() -> void:
	var boot: Dictionary = _boot_game_with_port(FakeSavePort.new())
	var game: Node = boot.game
	var save_port: FakeSavePort = boot.save_port
	var first_save_count := save_port.saves.size()
	var recruit_envelope := _envelope(game, "recruit_hero", {}, "recruit:seed:default:4")
	var recruit: Dictionary = game.execute_command(recruit_envelope)
	assert_true(recruit.ok, str(recruit))
	assert_eq(game.get_state().roster.size(), 5)
	assert_eq(game.get_state().economy.recruit_ticket, 3)
	assert_eq(save_port.saves.size(), first_save_count + 1)
	var replay: Dictionary = game.execute_command(recruit_envelope)
	assert_true(replay.ok, str(replay))
	assert_eq(game.get_state().roster.size(), 5)
	assert_eq(game.get_state().economy.recruit_ticket, 3)
	assert_eq(save_port.saves.size(), first_save_count + 1)

	for index: int in range(3):
		var next: Dictionary = _command(game, "recruit_hero", {}, "recruit:seed:default:%d" % (index + 5))
		assert_true(next.ok, str(next))
	assert_eq(game.get_state().roster.size(), 8)
	assert_eq(game.get_state().economy.recruit_ticket, 0)


func test_train_spends_books_and_gold_without_negative_balances() -> void:
	var game := _boot_game()
	var hero_id := str(game.get_state().roster.keys()[0])
	var train: Dictionary = _command(
		game,
		"train_hero",
		{"hero_id": hero_id, "xp_books": 1},
		"train:%s:l2" % hero_id,
	)
	assert_true(train.ok, str(train))
	assert_eq(game.get_state().roster[hero_id].level, 2)
	assert_eq(game.get_state().economy.xp_book, 1)
	assert_eq(game.get_state().economy.gold, 190)
	var rejected: Dictionary = _command(
		game,
		"train_hero",
		{"hero_id": hero_id, "xp_books": 99, "gold_cost": 99_999},
		"train:%s:too-expensive" % hero_id,
	)
	assert_false(rejected.ok)
	assert_eq(game.get_state().economy.gold, 190)


func test_set_formation_and_equip_item_are_reversible_meta_with_causal_receipts() -> void:
	var save_port := FakeSavePort.new()
	save_port.loaded_state = _equipment_state()
	var boot: Dictionary = _boot_game_with_port(save_port)
	var game: Node = boot.game
	var loaded_save_count := save_port.saves.size()
	var slots := {
		"front_1": "hero-a",
		"front_2": "hero-b",
		"back_1": "hero-c",
		"back_2": "hero-d",
	}
	var formation: Dictionary = _command(game, "set_formation", {"slots": slots}, "")
	assert_true(formation.ok, str(formation))
	assert_eq(game.get_state().formation.slots, slots)
	assert_eq(save_port.saves.size(), loaded_save_count)
	assert_true(
		game.get_state().receipt_ledgers.causal_by_command.has(formation.receipt.command_id)
	)

	var equip: Dictionary = _command(
		game, "equip_item", {"hero_id": "hero-a", "item_id": "item-1"}, ""
	)
	assert_true(equip.ok, str(equip))
	assert_eq(game.get_state().roster["hero-a"].equipment.weapon, "item-1")
	assert_eq(save_port.saves.size(), loaded_save_count)
	assert_true(game.get_state().receipt_ledgers.causal_by_command.has(equip.receipt.command_id))


func test_enhance_item_is_durable_value_and_persists_cost() -> void:
	var save_port := FakeSavePort.new()
	save_port.loaded_state = _equipment_state()
	var boot: Dictionary = _boot_game_with_port(save_port)
	var game: Node = boot.game
	var enhance: Dictionary = _command(game, "enhance_item", {"item_id": "item-1"}, "item:item-1:l1")
	assert_true(enhance.ok, str(enhance))
	assert_eq(game.get_state().inventory.items["item-1"].enhancement, 1)
	assert_eq(game.get_state().economy.gold, 920)
	assert_eq(game.get_state().economy.forge_stones, 19)
	assert_eq(save_port.saves.size(), 1)
	assert_true(game.get_state().receipt_ledgers.value_by_command.has(enhance.receipt.command_id))


func test_first_30m_stage_rewards_first_loss_once_and_guaranteed_blue() -> void:
	var fixture: Dictionary = _load_fixture()
	var game := _boot_game()
	var expected_total: Dictionary = fixture.planned_sources_total
	var path := [
		["stage-1-1", "win", "first_win"],
		["stage-1-2", "win", "first_win"],
		["stage-1-3", "loss", "first_loss"],
	]
	for step: Array in path:
		var reward: Dictionary = fixture.stage_rewards[step[0]][step[2]]
		var before: Dictionary = game.get_state().economy.duplicate(true)
		var result: Dictionary = _command(
			game,
			"settle_battle_result",
			{"stage_id": step[0], "outcome": step[1], "first_clear": step[1] == "win"},
			"stage:%s:%s" % [step[0], step[2]],
		)
		assert_true(result.ok, str(result))
		_assert_delta(game.get_state().economy, before, reward)

	var after_first_loss: Dictionary = game.get_state().economy.duplicate(true)
	var duplicate_loss: Dictionary = _command(
		game,
		"settle_battle_result",
		{"stage_id": "stage-1-3", "outcome": "loss"},
		"stage:stage-1-3:first_loss:duplicate-command",
	)
	assert_true(duplicate_loss.ok, str(duplicate_loss))
	assert_eq(game.get_state().economy, after_first_loss)

	var inventory_before: int = game.get_state().inventory.items.size()
	var first_win: Dictionary = _command(
		game,
		"settle_battle_result",
		{"stage_id": "stage-1-3", "outcome": "win", "first_clear": true},
		"stage:stage-1-3:first_win",
	)
	assert_true(first_win.ok, str(first_win))
	assert_eq(game.get_state().inventory.items.size(), inventory_before + 1)
	var item: Dictionary = game.get_state().inventory.items.values()[0]
	assert_eq(item.quality, "blue")
	assert_eq(game.get_state().pity.qualifying_drop_count, 0)
	assert_true(game.get_state().pity.first_guarantee_claimed)

	for step: Array in [
		["stage-1-4", "win", "first_win"],
		["stage-1-5", "loss", "first_loss"],
		["stage-1-5", "win", "first_win"],
	]:
		var result: Dictionary = _command(
			game,
			"settle_battle_result",
			{"stage_id": step[0], "outcome": step[1], "first_clear": step[1] == "win"},
			"stage:%s:%s" % [step[0], step[2]],
		)
		assert_true(result.ok, str(result))
	assert_eq(game.get_state().economy.gold, expected_total.gold)
	assert_eq(game.get_state().economy.recruit_ticket, expected_total.recruit_ticket)
	assert_eq(game.get_state().economy.xp_book, expected_total.xp_book)
	assert_eq(game.get_state().economy.forge_stone, expected_total.forge_stone)


func _equipment_state() -> Dictionary:
	var state: Dictionary = GameState.create_new(1_000, "save-equipment", 77)
	state.roster = {}
	for hero: Dictionary in HeroGenerator.generate_roster(77, 4):
		hero["equipment"] = {}
		state.roster[hero.id] = hero
	var hero_ids: Array = state.roster.keys()
	state.roster["hero-a"] = state.roster[hero_ids[0]]
	state.roster["hero-a"].id = "hero-a"
	state.roster["hero-b"] = state.roster[hero_ids[1]]
	state.roster["hero-b"].id = "hero-b"
	state.roster["hero-c"] = state.roster[hero_ids[2]]
	state.roster["hero-c"].id = "hero-c"
	state.roster["hero-d"] = state.roster[hero_ids[3]]
	state.roster["hero-d"].id = "hero-d"
	for hero_id: Variant in hero_ids:
		state.roster.erase(hero_id)
	state.inventory = {
		"items": {
			"item-1": {
				"id": "item-1",
				"template_id": "guardian_blade",
				"slot": "weapon",
				"quality": "blue",
				"affix_ids": [],
				"enhancement": 0,
			}
		}
	}
	state.economy = {
		"gold": 1000,
		"recruit_ticket": 0,
		"xp_book": 2,
		"forge_stone": 20,
		"recruit_tickets": 0,
		"experience_books": 2,
		"forge_stones": 20,
	}
	return state


func _load_fixture() -> Dictionary:
	var file := FileAccess.open(FixturePath, FileAccess.READ)
	assert_not_null(file)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary)
	return parsed


func _assert_delta(actual: Dictionary, before: Dictionary, delta: Dictionary) -> void:
	for resource: String in delta:
		if resource == "guaranteed_blue_item":
			continue
		assert_eq(int(actual.get(resource, 0)), int(before.get(resource, 0)) + int(delta[resource]))
