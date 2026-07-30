extends SceneTree

const MatchRulesScript = preload("res://features/match/match_rules.gd")
const HeroArchetypesScript = preload("res://features/actors/hero_archetypes.gd")
const ItemShopScript = preload("res://features/economy/item_shop.gd")
const ThreeLaneMatchScript = preload("res://features/match/three_lane_match.gd")
var failures: Array[String] = []

func _init() -> void:
	_run()

func _run() -> void:
	_check(MatchRulesScript.TEAM_SIZE == 5, "mode owns a five-player team contract")
	_check(MatchRulesScript.lane_name(MatchRulesScript.Lane.MID) == "MID", "three-lane vocabulary is stable")
	_check(MatchRulesScript.is_valid_team_roster(["a", "b", "c", "d", "e"]), "five unique heroes are a valid roster")
	_check(not MatchRulesScript.is_valid_team_roster(["a", "b", "b", "c", "d"]), "duplicate hero selection is rejected")
	_check(HeroArchetypesScript.has("mira") and HeroArchetypesScript.get_hero("mira").signature == "Comet Array", "original hero data is addressable")
	var bought := ItemShopScript.buy("pulse_lens", 500)
	_check(bool(bought.ok) and int(bought.gold) == 150, "shop purchase deducts exact gold")
	_check(not bool(ItemShopScript.buy("wardens_plate", 10).ok), "shop refuses unaffordable purchase")
	var arena := ThreeLaneMatchScript.new()
	_check(arena.tower_hp.size() == 3 and arena.core_hp.size() == 2, "three-lane match creates towers and both relay cores")
	arena.set_wave(MatchRulesScript.Lane.MID, ThreeLaneMatchScript.Team.DAWN, 9)
	arena.set_wave(MatchRulesScript.Lane.MID, ThreeLaneMatchScript.Team.DUSK, 0)
	arena.tick(200.0)
	_check(arena.tower_hp[MatchRulesScript.Lane.MID][ThreeLaneMatchScript.Team.DUSK] == 0, "pushing wave destroys exposed outer tower")
	arena.tick(200.0)
	_check(arena.outcome == ThreeLaneMatchScript.Team.DAWN, "destroying a core resolves a deterministic winner")
	arena.reset()
	var dusk_before := int(arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.MID)[0].hp)
	var vesper_position_before := float(arena.player_hero_by_slot(1).lane_position)
	_check(arena.player_cast(MatchRulesScript.Lane.MID), "player skill finds a living enemy in its lane")
	var dusk_after := int(arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.MID)[0].hp)
	_check(dusk_after == dusk_before - 34, "player skill applies authored damage")
	_check(String(arena.last_ability_result.hero_id) == "vesper" and String(arena.last_ability_result.effect) == "DASH", "legacy lane cast delegates to Vesper's slot-authored Rift Step")
	_check(
		float(arena.player_hero_by_slot(1).lane_position) > vesper_position_before
		and is_equal_approx(float(arena.last_ability_result.get("from")), vesper_position_before)
		and is_equal_approx(float(arena.last_ability_result.get("to")), float(arena.player_hero_by_slot(1).lane_position))
		and float(arena.last_ability_result.get("travel")) > 0.0,
		"Rift Step authoritatively advances Vesper and publishes its movement coordinates"
	)
	_check(int(arena.last_ability_result.target_slot) == 1, "Rift Step publishes the selected target slot")
	arena.reset()
	var purchase := arena.player_buy("pulse_lens", MatchRulesScript.Lane.MID)
	_check(bool(purchase.ok) and int(arena.gold[ThreeLaneMatchScript.Team.DAWN]) == 150, "match purchase owns exact gold mutation")
	_check(arena.inventory == ["pulse_lens"] and arena.player_attack_bonus == 12, "purchased lens enters inventory and raises attack")
	var enhanced_before := int(arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.MID)[0].hp)
	arena.player_cast(MatchRulesScript.Lane.MID)
	var enhanced_after := int(arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.MID)[0].hp)
	_check(enhanced_after == enhanced_before - 46, "inventory attack bonus changes real skill damage")
	_check(not bool(arena.player_buy("pulse_lens", MatchRulesScript.Lane.MID).ok), "insufficient gold rejects a second lens without mutation")
	arena.reset()
	var target: Dictionary = arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.MID)[0]
	var caster: Dictionary = arena.player_hero(MatchRulesScript.Lane.MID)
	_check(String(caster.name) == "Vesper" and String(caster.role) == "Skirmisher", "selected lane resolves an original hero archetype")
	target.hp = 20.0
	var kill_gold_before := int(arena.gold[ThreeLaneMatchScript.Team.DAWN])
	_check(arena.player_cast(MatchRulesScript.Lane.MID), "player cast reaches a low-health lane target")
	_check(float(target.hp) == 0.0 and float(target.respawn_remaining) == ThreeLaneMatchScript.HERO_RESPAWN_SECONDS, "lethal skill starts authored respawn timer")
	_check(int(arena.team_kills[ThreeLaneMatchScript.Team.DAWN]) == 1 and int(arena.gold[ThreeLaneMatchScript.Team.DAWN]) == kill_gold_before + ThreeLaneMatchScript.HERO_KILL_GOLD, "hero elimination awards one kill and exact gold")
	_check(int(caster.kills) == 1 and int(caster.level) == 2 and int(caster.xp) == 0, "hero kill grants XP and one deterministic level")
	_check(float(caster.attack) == float(HeroArchetypesScript.get_hero("vesper").attack) + 3.0 and float(caster.max_hp) == 110.0, "level-up increases authored combat stats")
	arena.tick(4.0)
	_check(float(target.hp) == 0.0 and is_equal_approx(float(target.respawn_remaining), 4.0), "dead hero remains unavailable during respawn")
	arena.tick(4.1)
	_check(float(target.hp) == float(target.max_hp) and float(target.spawn_protection) > 0.0, "hero redeploys at full health with spawn protection")
	arena.reset()
	var duel_target: Dictionary = arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.TOP)[0]
	var duel_before := float(duel_target.hp)
	for _frame in 60: arena.tick(1.0 / 60.0)
	_check(float(duel_target.hp) < duel_before, "bot combat accumulates damage across normal 60 FPS frame deltas")
	arena.reset()
	for slot in ThreeLaneMatchScript.HERO_IDS.size():
		_check(String(arena.player_hero_by_slot(slot).hero_id) == ThreeLaneMatchScript.HERO_IDS[slot], "Dawn hero slot %d resolves its stable authored hero" % slot)
	var aerion: Dictionary = arena.player_hero_by_slot(0)
	var guard := arena.player_cast_for_slot(0)
	_check(bool(guard.ok) and String(guard.effect) == "SHIELD" and float(aerion.shield) == ThreeLaneMatchScript.AERION_SHIELD, "Aerion Solar Guard creates authoritative shield")
	arena._apply_damage(aerion, 20.0, ThreeLaneMatchScript.Team.DUSK)
	_check(float(aerion.hp) == 100.0 and float(aerion.shield) == 8.0, "Solar Guard shield absorbs incoming damage before health")
	arena.reset()
	var mira_targets: Array[Dictionary] = arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.BOTTOM)
	var comet := arena.player_cast_for_slot(2)
	_check(bool(comet.ok) and String(comet.effect) == "AREA_DAMAGE" and int(comet.targets) == 2, "Mira Comet Array hits every living enemy in bottom lane")
	_check(mira_targets.all(func(h: Dictionary) -> bool: return float(h.hp) == 78.0), "Comet Array applies its authored damage to both targets")
	arena.reset()
	var bottom_allies: Array[Dictionary] = arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DAWN and int(h.lane) == MatchRulesScript.Lane.BOTTOM)
	for ally in bottom_allies: ally.hp = 50.0
	var anchor := arena.player_cast_for_slot(3)
	_check(bool(anchor.ok) and String(anchor.effect) == "TEAM_HEAL" and int(anchor.targets) == 2, "Orun Anchor Field affects both living lane allies")
	_check(bottom_allies.all(func(h: Dictionary) -> bool: return float(h.hp) == 74.0), "Anchor Field restores authored health to both allies")
	arena.reset()
	var sable_target: Dictionary = arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.TOP)[0]
	var prism := arena.player_cast_for_slot(4)
	_check(bool(prism.ok) and String(prism.effect) == "LONG_RANGE" and String(prism.range) == "LONG", "Sable Prism Shot exposes high-range semantics")
	_check(float(sable_target.hp) == 48.0, "Prism Shot applies the roster's highest single-target base damage")
	_check(
		is_equal_approx(float(prism.cast_range), ThreeLaneMatchScript.SABLE_CAST_RANGE)
		and float(prism.distance) <= float(prism.cast_range)
		and int(prism.target_slot) == 0,
		"Prism Shot publishes its numeric range, target distance and deterministic nearest target"
	)
	_check(int(prism.pressure_delta) == 1, "an effective signature publishes one authoritative pressure increment")
	arena.reset()
	var far_target: Dictionary = arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.MID)[0]
	var far_vesper: Dictionary = arena.player_hero_by_slot(1)
	far_vesper.lane_position = 0.10
	far_target.lane_position = 0.65
	var far_vesper_before := float(far_vesper.lane_position)
	var short_cast := arena.player_cast_for_slot(1)
	_check(
		not bool(short_cast.ok)
		and String(short_cast.reason) == "OUT_OF_RANGE"
		and is_equal_approx(float(short_cast.distance), 0.55)
		and is_equal_approx(float(short_cast.cast_range), ThreeLaneMatchScript.VESPER_CAST_RANGE)
		and int(short_cast.target_slot) == 1
		and int(short_cast.pressure_delta) == 0,
		"Vesper range rejection publishes actual distance, numeric limit and target without pressure"
	)
	_check(float(far_target.hp) == 100.0 and is_equal_approx(float(far_vesper.lane_position), far_vesper_before), "out-of-range Rift Step leaves target health and caster position unchanged")
	var far_sable: Dictionary = arena.player_hero_by_slot(4)
	far_sable.lane = MatchRulesScript.Lane.MID
	far_sable.lane_position = 0.10
	var long_cast := arena.player_cast_for_slot(4)
	_check(
		bool(long_cast.ok)
		and String(long_cast.effect) == "LONG_RANGE"
		and float(long_cast.distance) > ThreeLaneMatchScript.VESPER_CAST_RANGE
		and float(long_cast.distance) <= ThreeLaneMatchScript.SABLE_CAST_RANGE,
		"Sable hits the same distant target that is outside Vesper's numeric cast range"
	)
	_check(float(far_target.hp) == 48.0 and int(long_cast.target_slot) == 1, "long-range targeting mutates only the selected distant target")
	arena.reset()
	var dead_caster := arena.player_hero_by_slot(1)
	dead_caster.hp = 0.0
	var dead_cast := arena.player_cast_for_slot(1)
	_check(not bool(dead_cast.ok) and String(dead_cast.reason) == "HERO_DEAD" and int(dead_cast.pressure_delta) == 0, "dead heroes cannot cast or create lane pressure")
	arena.reset()
	var protected_target: Dictionary = arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.MID)[0]
	protected_target.spawn_protection = 1.0
	var protected_cast := arena.player_cast_for_slot(1)
	_check(not bool(protected_cast.ok) and String(protected_cast.reason) == "NO_TARGET", "spawn-protected enemies are not valid signature targets")
	_check(float(arena.player_hero_by_slot(1).ability_cooldown_remaining) == 0.0, "a no-target cast does not enter cooldown")
	arena.reset()
	aerion = arena.player_hero_by_slot(0)
	aerion.shield = 60.0
	var capped_guard := arena.player_cast_for_slot(0)
	_check(not bool(capped_guard.ok) and String(capped_guard.reason) == "NO_EFFECT", "Solar Guard reports no effect at the shield cap")
	_check(float(aerion.ability_cooldown_remaining) == 0.0, "a capped shield does not enter cooldown")
	arena._apply_damage(aerion, 60.0, ThreeLaneMatchScript.Team.DUSK)
	_check(float(aerion.hp) == 100.0 and float(aerion.shield) == 0.0, "a capped Solar Guard shield can fully absorb an equal hit")
	arena.reset()
	var full_health_anchor := arena.player_cast_for_slot(3)
	_check(not bool(full_health_anchor.ok) and String(full_health_anchor.reason) == "NO_EFFECT" and int(full_health_anchor.pressure_delta) == 0, "Anchor Field on full-health allies is a zero-effect cast")
	_check(float(arena.player_hero_by_slot(3).ability_cooldown_remaining) == 0.0, "zero healing does not enter cooldown")
	arena.reset()
	var first_cast := arena.player_cast_for_slot(1)
	var cooldown_cast := arena.player_cast_for_slot(1)
	_check(bool(first_cast.ok) and is_equal_approx(float(arena.player_hero_by_slot(1).ability_cooldown_remaining), ThreeLaneMatchScript.ABILITY_COOLDOWN_SECONDS), "an effective skill starts the unified per-hero cooldown")
	_check(not bool(cooldown_cast.ok) and String(cooldown_cast.reason) == "COOLDOWN" and int(cooldown_cast.pressure_delta) == 0, "cooldown rejects repeat casts without pressure")
	arena.tick(ThreeLaneMatchScript.ABILITY_COOLDOWN_SECONDS)
	_check(float(arena.player_hero_by_slot(1).ability_cooldown_remaining) == 0.0, "match tick deterministically clears elapsed hero cooldown")
	arena.reset()
	var complete_target: Dictionary = arena.heroes.filter(func(h: Dictionary) -> bool: return int(h.team) == ThreeLaneMatchScript.Team.DUSK and int(h.lane) == MatchRulesScript.Lane.MID)[0]
	var complete_caster: Dictionary = arena.player_hero_by_slot(1)
	var complete_target_hp := float(complete_target.hp)
	var complete_caster_position := float(complete_caster.lane_position)
	var complete_event := arena.last_event
	var complete_result := arena.last_ability_result.duplicate(true)
	arena.outcome = ThreeLaneMatchScript.Team.DAWN
	var complete_cast := arena.player_cast_for_slot(1)
	_check(not bool(complete_cast.ok) and String(complete_cast.reason) == "MATCH_COMPLETE" and int(complete_cast.pressure_delta) == 0, "completed matches reject authoritative casts with no pressure")
	_check(
		is_equal_approx(float(complete_target.hp), complete_target_hp)
		and is_equal_approx(float(complete_caster.lane_position), complete_caster_position)
		and float(complete_caster.ability_cooldown_remaining) == 0.0,
		"post-match casts do not mutate combat position, health or cooldown"
	)
	_check(arena.last_event == complete_event and arena.last_ability_result == complete_result, "post-match rejection does not replace the frozen match presentation state")
	if failures.is_empty():
		print("MOBA_DOMAIN_TESTS_OK")
		quit(0)
		return
	for failure in failures: push_error(failure)
	print("MOBA_DOMAIN_TESTS_FAIL: %d" % failures.size())
	quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
