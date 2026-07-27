class_name ResearchBreakthroughService
extends RefCounted

const ResearchBreakthroughCatalogScript := preload(
	"res://game/scripts/content/research_breakthrough_catalog.gd"
)
const SignalRecruitServiceScript := preload(
	"res://game/scripts/domain/recruitment/signal_recruit_service.gd"
)


const CLAIM_KEY: String = ResearchBreakthroughCatalogScript.CLAIM_KEY
const LEGACY_CLAIM_KEY: String = ResearchBreakthroughCatalogScript.LEGACY_CLAIM_KEY
const FACTION_CLAIM_KEY: String = "reward.post_chapter_faction_ten"


static func claim(state: RefCounted) -> Dictionary:
	var content_errors := ResearchBreakthroughCatalogScript.validate_all()
	if not content_errors.is_empty():
		return {
			"ok": false,
			"error": "RESEARCH_BREAKTHROUGH_CONTENT_INVALID: %s" % "; ".join(content_errors),
		}
	if not bool(state.factory.eligible_facilities.get("research_lab", false)):
		return {"ok": false, "error": "FOUNDATIONAL_SIGNAL_NOT_DETECTED"}
	var claimed := state.onboarding.get("claimed", {}) as Dictionary
	if claimed.has(CLAIM_KEY) or claimed.has(LEGACY_CLAIM_KEY):
		return {"ok": false, "error": "FOUNDATIONAL_SIGNAL_ALREADY_CLAIMED"}
	var results: Array[Dictionary] = []
	var revealed_recipe_ids: Dictionary = {}
	for definition in ResearchBreakthroughCatalogScript.CARDS:
		var recipe_id := String(definition.recipe_id)
		var rarity := String(definition.rarity)
		var archetype_id := String(definition.archetype_id)
		var is_duplicate := revealed_recipe_ids.has(recipe_id)
		if not is_duplicate:
			revealed_recipe_ids[recipe_id] = true
			if (
				not bool(state.factory.discovered_blueprints.get(recipe_id, false))
				and not bool(state.factory.blueprints.get(recipe_id, false))
			):
				state.factory.discovered_blueprints[recipe_id] = true
		results.append({
			"rarity": rarity,
			"archetype_id": archetype_id,
			"recipe_id": recipe_id,
			"kind": "blueprint_fragment" if is_duplicate else "blueprint",
		})
	claimed[CLAIM_KEY] = true
	state.onboarding["claimed"] = claimed
	return {"ok": true, "event": {
		"type": "foundational_signal_resolved",
		"count": results.size(),
		"results": results,
		"guaranteed_recipe_ids": ResearchBreakthroughCatalogScript.guaranteed_recipe_ids(),
		"pity_advanced": false,
	}}


static func claim_faction_ten(state: RefCounted) -> Dictionary:
	if not (state.stage_progress.get("cleared_stages", []) as Array).has("stage_1_5"):
		return {"ok": false, "error": "FACTION_SIGNAL_LOCKED"}
	var claimed := state.onboarding.get("claimed", {}) as Dictionary
	if claimed.has(FACTION_CLAIM_KEY):
		return {"ok": false, "error": "FACTION_SIGNAL_ALREADY_CLAIMED"}
	var result := SignalRecruitServiceScript.recruit_free_faction_ten(state)
	if not bool(result.get("ok", false)):
		return result
	claimed[FACTION_CLAIM_KEY] = true
	state.onboarding["claimed"] = claimed
	return result


static func is_claimed(state: RefCounted) -> bool:
	var claimed := state.onboarding.get("claimed", {}) as Dictionary
	return claimed.has(CLAIM_KEY) or claimed.has(LEGACY_CLAIM_KEY)


static func is_faction_claimed(state: RefCounted) -> bool:
	return (state.onboarding.get("claimed", {}) as Dictionary).has(FACTION_CLAIM_KEY)
