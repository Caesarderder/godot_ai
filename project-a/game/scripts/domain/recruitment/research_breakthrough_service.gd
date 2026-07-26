class_name ResearchBreakthroughService
extends RefCounted

const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const ResearchBreakthroughCatalogScript := preload(
	"res://game/scripts/content/research_breakthrough_catalog.gd"
)


static func claim(state: RefCounted) -> Dictionary:
	var content_errors := ResearchBreakthroughCatalogScript.validate_all()
	if not content_errors.is_empty():
		return {
			"ok": false,
			"error": "RESEARCH_BREAKTHROUGH_CONTENT_INVALID: %s" % "; ".join(content_errors),
		}
	if int(state.factory.facilities.get("research_lab", 0)) <= 0:
		return {"ok": false, "error": "RESEARCH_BREAKTHROUGH_REQUIRES_LAB"}
	var claimed := state.onboarding.get("claimed", {}) as Dictionary
	if claimed.has(ResearchBreakthroughCatalogScript.CLAIM_KEY):
		return {"ok": false, "error": "RESEARCH_BREAKTHROUGH_ALREADY_CLAIMED"}
	var results: Array[Dictionary] = []
	for definition in ResearchBreakthroughCatalogScript.CARDS:
		var kind := String(definition.kind)
		if kind != "hero":
			results.append({
				"rarity": String(definition.rarity),
				"kind": kind,
				"amount": int(definition.amount),
			})
			continue
		var recipe_id := String(definition.recipe_id)
		var archetype_id := String(definition.archetype_id)
		var existing := _hero_for_archetype(state, archetype_id)
		var result := {
			"rarity": String(definition.rarity),
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
				String(definition.class_id)
			)
			hero.display_name = HeroGeneratorScript.archetype_display_name(archetype_id)
			hero.aptitude_id = "A"
			state.roster.append(hero)
			result["kind"] = "hero"
			result["hero_id"] = hero.hero_id
		else:
			state.meta_progression.hero_data[archetype_id] = int(
				state.meta_progression.hero_data.get(archetype_id, 0)
			) + int(definition.duplicate_data_amount)
			result["kind"] = "hero_data"
			result["amount"] = int(definition.duplicate_data_amount)
		results.append(result)
	state.economy.skill_chips += ResearchBreakthroughCatalogScript.skill_chip_grant()
	state.factory.grant(ResearchBreakthroughCatalogScript.material_grant())
	claimed[ResearchBreakthroughCatalogScript.CLAIM_KEY] = true
	state.onboarding["claimed"] = claimed
	return {
		"ok": true,
		"event": {
			"type": "research_breakthrough_resolved",
			"count": results.size(),
			"results": results,
			"guaranteed_archetypes": ResearchBreakthroughCatalogScript.guaranteed_archetypes(),
			"pity_advanced": false,
		},
	}


static func is_claimed(state: RefCounted) -> bool:
	return (state.onboarding.get("claimed", {}) as Dictionary).has(
		ResearchBreakthroughCatalogScript.CLAIM_KEY
	)


static func _hero_for_archetype(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null
