class_name ResearchBreakthroughService
extends RefCounted

const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")

const CLAIM_KEY: String = "reward.research_breakthrough_ten"
const FOUNDATIONAL: Array[Dictionary] = [
	{
		"rarity": "A",
		"recipe_id": "ordinary.assault",
		"archetype_id": "assault",
		"class_id": "fighter",
	},
	{
		"rarity": "A",
		"recipe_id": "heavy.armored",
		"archetype_id": "armored",
		"class_id": "guardian",
	},
]


static func claim(state: RefCounted) -> Dictionary:
	if int(state.factory.facilities.get("research_lab", 0)) <= 0:
		return {"ok": false, "error": "RESEARCH_BREAKTHROUGH_REQUIRES_LAB"}
	var claimed := state.onboarding.get("claimed", {}) as Dictionary
	if claimed.has(CLAIM_KEY):
		return {"ok": false, "error": "RESEARCH_BREAKTHROUGH_ALREADY_CLAIMED"}
	var results: Array[Dictionary] = []
	for definition in FOUNDATIONAL:
		var recipe_id := String(definition["recipe_id"])
		var archetype_id := String(definition["archetype_id"])
		var existing := _hero_for_archetype(state, archetype_id)
		var result := {
			"rarity": String(definition["rarity"]),
			"recipe_id": recipe_id,
			"archetype_id": archetype_id,
		}
		state.factory.blueprints[recipe_id] = true
		state.factory.model_tech_stars[recipe_id] = maxi(
			1,
			int(state.factory.model_tech_stars.get(recipe_id, 0))
		)
		state.factory.discovered_blueprints.erase(recipe_id)
		if existing == null:
			var roster_index := int(state.allocate_hero_index())
			var hero: RefCounted = HeroGeneratorScript.generate_archetype(
				state.run_seed,
				roster_index,
				archetype_id,
				String(definition["class_id"])
			)
			hero.display_name = HeroGeneratorScript.archetype_display_name(archetype_id)
			hero.aptitude_id = "A"
			state.roster.append(hero)
			result["kind"] = "hero"
			result["hero_id"] = hero.hero_id
		else:
			state.meta_progression.hero_data[archetype_id] = int(
				state.meta_progression.hero_data.get(archetype_id, 0)
			) + 2
			result["kind"] = "hero_data"
			result["amount"] = 2
		results.append(result)
	var resource_cards: Array[Dictionary] = [
		{"rarity": "A", "kind": "skill_chip", "amount": 1},
		{"rarity": "R", "kind": "porcelain", "amount": 6},
		{"rarity": "R", "kind": "porcelain", "amount": 6},
		{"rarity": "R", "kind": "porcelain", "amount": 6},
		{"rarity": "R", "kind": "parts", "amount": 5},
		{"rarity": "R", "kind": "parts", "amount": 5},
		{"rarity": "R", "kind": "sludge", "amount": 4},
		{"rarity": "R", "kind": "sludge", "amount": 4},
	]
	for card in resource_cards:
		results.append(card.duplicate(true))
	state.economy.skill_chips += 1
	state.factory.grant({"porcelain": 18, "parts": 10, "sludge": 8})
	claimed[CLAIM_KEY] = true
	state.onboarding["claimed"] = claimed
	return {
		"ok": true,
		"event": {
			"type": "research_breakthrough_resolved",
			"count": results.size(),
			"results": results,
			"guaranteed_archetypes": ["assault", "armored"],
			"pity_advanced": false,
		},
	}


static func is_claimed(state: RefCounted) -> bool:
	return (state.onboarding.get("claimed", {}) as Dictionary).has(CLAIM_KEY)


static func _hero_for_archetype(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null
