extends SceneTree

const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")

var failures: Array[String] = []

const CHAPTER_EPISODE_RANGES: Dictionary = {
	1: Vector2i(7, 20),
	2: Vector2i(21, 32),
	3: Vector2i(33, 49),
	4: Vector2i(50, 57),
	5: Vector2i(58, 74),
}
const CANONICAL_ARCHETYPE_NAMES: Dictionary = {
	"gman": "Gman",
	"assault": "普通马桶人",
	"sonic": "故障闪电马桶人",
	"rocket": "飞行四发射器马桶人",
	"bomber": "炸弹桶马桶人",
	"armored": "激光火箭筒马桶人",
	"saw": "飞行双圆锯马桶人",
	"repair": "研究员马桶人",
	"parasite": "大型寄生虫马桶人",
	"signal_purifier": "钢爪马桶人科学家",
	"anchor_bastion": "巨型飞行马桶人",
	"magnetic_conductor": "冲击波直升机马桶人",
	"phase_tunneler": "武士刀蜘蛛马桶人",
	"protocol_weaver": "寄生虫马桶人",
	"ram_breaker": "喷气背包钢爪马桶人",
	"smoke_screen": "硫酸桶马桶人",
	"mortar": "喷气背包六发射器马桶人",
	"interceptor": "直升机马桶人",
	"bulwark": "多头马桶人",
	"crusher": "圆锯突变马桶人",
	"echo_mimic": "DJ马桶人",
	"drain_engine": "吸尘小便池人",
	"swarm_beacon": "直升机寄生虫马桶人",
	"chronolock": "硫酸骷髅马桶人",
}


func _init() -> void:
	_check_catalog()
	_check_canonical_archetypes()
	_check_counter_research()
	if failures.is_empty():
		print("CAMPAIGN_60_STAGE_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("CAMPAIGN_60_STAGE_TESTS_FAIL: %d" % failures.size())
	quit(1)


func _check_catalog() -> void:
	var ids := StageCatalogScript.all_stage_ids()
	_check(ids.size() == 60, "campaign owns exactly 60 stages")
	_check(_unique_count(ids) == 60, "all campaign stage ids are unique")
	var display_names: Array[String] = []
	var episode_pattern := RegEx.new()
	episode_pattern.compile("E([0-9]{2}) · ")
	_check(StageCatalogScript.next_stage_id("stage_1_12") == "stage_2_1", "chapter boundary is contiguous")
	_check(StageCatalogScript.next_stage_id("stage_5_12") == "endless_1", "final boss opens endless")
	for chapter in range(1, 6):
		var previous_power := 0
		for stage_number in range(1, 13):
			var stage_id := "stage_%d_%d" % [chapter, stage_number]
			var config := StageCatalogScript.stage(stage_id)
			_check(not config.is_empty(), "%s resolves" % stage_id)
			var display_name := String(config.get("display_name", ""))
			display_names.append(display_name)
			var episode_match := episode_pattern.search(display_name)
			_check(episode_match != null, "%s includes an E## canon anchor" % stage_id)
			if episode_match != null:
				var episode := int(episode_match.get_string(1))
				var allowed: Vector2i = CHAPTER_EPISODE_RANGES[chapter]
				_check(
					episode >= allowed.x and episode <= allowed.y,
					"%s episode belongs to chapter canon range" % stage_id
				)
			var power := int(config.get("recommended_power", 0))
			_check(power >= previous_power, "%s recommendation is monotonic" % stage_id)
			previous_power = power
			var expected_tier := (
				"boss" if stage_number == 12
				else ("elite" if stage_number in [3, 6, 9] else ("checkpoint" if stage_number % 3 == 2 else "normal"))
			)
			_check(String(config.get("encounter_tier", "")) == expected_tier, "%s tier follows 3-stage rhythm" % stage_id)
			if chapter >= 2 and stage_number in [9, 12]:
				_check(not String(config.get("required_counter_tech", "")).is_empty(), "%s requires chapter counter tech" % stage_id)
			elif chapter == 1:
				_check(String(config.get("required_counter_tech", "")).is_empty(), "%s has no anachronistic counter tech" % stage_id)
	_check(_unique_count(display_names) == 60, "all campaign display names are unique")
	for stage_number in range(1, 13):
		var chapter_one := StageCatalogScript.stage("stage_1_%d" % stage_number)
		_check(String(chapter_one.get("required_counter_tech", "")).is_empty(), "chapter one has no TV-era counter tech")
		_check(int(chapter_one.get("tv_signal_period_ticks", 0)) == 0, "chapter one has no TV mechanic")
	for stage_number in range(1, 4):
		var chapter_two_opening := StageCatalogScript.stage("stage_2_%d" % stage_number)
		_check(_all_enemy_ids_start_with(chapter_two_opening, "camera_"), "E21-E23 retain Cameramen enemies")
		_check(int(chapter_two_opening.get("resonance_period_ticks", 0)) == 0, "E21-E23 have no Speaker resonance")
		var chapter_three_opening := StageCatalogScript.stage("stage_3_%d" % stage_number)
		_check(_all_enemy_ids_start_with(chapter_three_opening, "camera_"), "E33-E38 retain pre-TV Alliance enemies")
		_check(int(chapter_three_opening.get("tv_signal_period_ticks", 0)) == 0, "E33-E38 have no TV mechanics")
	_check(_all_enemy_ids_start_with(StageCatalogScript.stage("stage_2_4"), "speaker_"), "E24 introduces Speaker enemies")
	_check(_all_enemy_ids_start_with(StageCatalogScript.stage("stage_3_4"), "tv_"), "E39 introduces TV enemies")
	_check(String(StageCatalogScript.stage("stage_5_12").get("display_name", "")).contains("E73 ·"), "playable campaign ends at E73")
	for structure in StageCatalogScript.stage("stage_5_12").get("structures", []):
		_check(not String(structure.get("display_name", "")).contains("Astro"), "E73 playable structures remain Alliance targets")
	var epilogue := StageCatalogScript.epilogue_contract()
	_check(int(epilogue.get("episode", 0)) == 74 and not bool(epilogue.get("playable", true)), "non-playable epilogue previews E74 Astro fleet")


func _check_canonical_archetypes() -> void:
	var archetypes := FactoryCatalogScript.archetypes()
	_check(archetypes.size() == CANONICAL_ARCHETYPE_NAMES.size(), "stable archetype count remains unchanged")
	for archetype_id in CANONICAL_ARCHETYPE_NAMES:
		_check(archetypes.has(archetype_id), "stable archetype id remains present: %s" % archetype_id)
		var expected_name := String(CANONICAL_ARCHETYPE_NAMES[archetype_id])
		_check(
			String((archetypes.get(archetype_id, {}) as Dictionary).get("display_name", "")) == expected_name,
			"%s uses canonical character or faction name" % archetype_id
		)
		_check(
			HeroGeneratorScript.archetype_display_name(archetype_id) == expected_name,
			"%s recruitment name matches factory catalog" % archetype_id
		)
	var recipe_ids: Array[String] = []
	var unique_character_names := [
		"DJ Skibidi Toilet",
		"DJ Skibidi Toilet 2.0",
		"Glitch Skibidi Toilet",
		"Buzzsaw Skibidi Mutant",
		"Berserker Skibidi Mutant",
		"Repairer Skibidi Toilet",
		"Chief Scientist Skibidi Toilet",
	]
	for recipe in FactoryCatalogScript.recipes():
		recipe_ids.append(String(recipe.get("recipe_id", "")))
		_check(
			not unique_character_names.has(String(recipe.get("display_name", ""))),
			"repeatable recipes do not clone named unique characters"
		)
		_check(
			String(recipe.get("display_name", "")) == String(CANONICAL_ARCHETYPE_NAMES.get(String(recipe.get("archetype_id", "")), "")),
			"recipe display name follows canonical archetype map"
		)
	_check(_unique_count(recipe_ids) == 23, "all 23 craftable stable recipe ids remain unique")
	_check(FactoryCatalogScript.recipe_for_archetype("gman").is_empty(), "G-Toilet remains a unique non-craftable commander")


func _check_counter_research() -> void:
	var state := GameStateScript.create_new(20260729, 1000, false)
	state.factory.materials["porcelain"] = 100
	state.stage_progress["cleared_stages"] = ["stage_2_8"]
	var executor := CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var envelope := {
		"type": "research_counter_tech",
		"command_id": "counter-tech-test",
		"business_key": "counter-tech:counter.resonance_insulation",
		"expected_revision": state.revision,
		"payload": {"tech_id": "counter.resonance_insulation", "chapter": 2},
	}
	var result := executor.execute(envelope)
	_check(bool(result.get("ok", false)), "eligible resonance research succeeds")
	var current := executor.state
	_check(int(current.factory.materials["porcelain"]) == 74, "research deducts exact industrial cost")
	_check((current.receipt_ledgers["durable"] as Dictionary).has("counter_tech:counter.resonance_insulation"), "research writes durable ownership")
	var replay := executor.execute(envelope)
	_check(bool(replay.get("ok", false)), "exact command replay returns prior result")
	_check(int(executor.state.factory.materials["porcelain"]) == 74, "replay cannot double-charge")


func _unique_count(values: Array[String]) -> int:
	var seen: Dictionary = {}
	for value in values:
		seen[value] = true
	return seen.size()


func _all_enemy_ids_start_with(config: Dictionary, prefix: String) -> bool:
	for enemy in config.get("enemies", []):
		var archetype_id := String(enemy.get("archetype_id", ""))
		if archetype_id == "core_guard":
			continue
		if not archetype_id.begins_with(prefix):
			return false
	return true


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
