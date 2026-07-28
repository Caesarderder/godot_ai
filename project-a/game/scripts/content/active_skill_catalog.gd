class_name ActiveSkillCatalog
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const DEFINITIONS: Array[Resource] = [
	preload("res://game/resources/definitions/skills/active/gman_overrun.tres"),
	preload("res://game/resources/definitions/skills/active/plunger_charge.tres"),
	preload("res://game/resources/definitions/skills/active/sonic_disruptor.tres"),
	preload("res://game/resources/definitions/skills/active/rocket_salvo.tres"),
	preload("res://game/resources/definitions/skills/active/suicide_dive.tres"),
	preload("res://game/resources/definitions/skills/active/siege_shield.tres"),
	preload("res://game/resources/definitions/skills/active/saw_rush.tres"),
	preload("res://game/resources/definitions/skills/active/field_repair.tres"),
	preload("res://game/resources/definitions/skills/active/parasite_swarm.tres"),
	preload("res://game/resources/definitions/skills/active/signal_cleanse.tres"),
	preload("res://game/resources/definitions/skills/active/formation_anchor.tres"),
	preload("res://game/resources/definitions/skills/active/magnetic_convergence.tres"),
	preload("res://game/resources/definitions/skills/active/phase_breach.tres"),
	preload("res://game/resources/definitions/skills/active/protocol_hijack.tres"),
	preload("res://game/resources/definitions/skills/active/ram_shatter.tres"),
	preload("res://game/resources/definitions/skills/active/caustic_smokescreen.tres"),
	preload("res://game/resources/definitions/skills/active/sewer_mortar.tres"),
	preload("res://game/resources/definitions/skills/active/warning_intercept.tres"),
	preload("res://game/resources/definitions/skills/active/linked_bulwark.tres"),
	preload("res://game/resources/definitions/skills/active/hydraulic_crush.tres"),
	preload("res://game/resources/definitions/skills/active/allied_echo.tres"),
	preload("res://game/resources/definitions/skills/active/energy_siphon.tres"),
	preload("res://game/resources/definitions/skills/active/decoy_bloom.tres"),
	preload("res://game/resources/definitions/skills/active/chrono_lock.tres"),
]


static func definition(skill_id: String) -> Resource:
	for item in DEFINITIONS:
		if String(item.skill_id) == skill_id:
			return item
	return null


static func view(skill_id: String) -> Dictionary:
	var item := definition(skill_id)
	if item == null:
		return {}
	return {
		"skill_id": String(item.skill_id),
		"archetype_id": String(item.archetype_id),
		"display_name": item.display_name,
		"short_label": item.short_label,
		"role_copy": item.role_copy,
		"effect_copy": item.effect_copy,
		"timing_copy": item.timing_copy,
	}


static func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	var archetypes: Dictionary = {}
	for item in DEFINITIONS:
		if item == null:
			errors.append("active skill definition preload returned null")
			continue
		var skill_id := String(item.skill_id)
		var archetype_id := String(item.archetype_id)
		if ids.has(skill_id):
			errors.append("duplicate active skill id: %s" % skill_id)
		if archetypes.has(archetype_id):
			errors.append("duplicate active skill archetype: %s" % archetype_id)
		ids[skill_id] = true
		archetypes[archetype_id] = true
		for error in item.validation_errors():
			errors.append(String(error))
	for archetype_id in FactoryCatalogScript.archetypes():
		var skill_id := FactoryCatalogScript.active_skill_for_archetype(String(archetype_id))
		var item := definition(skill_id)
		if item == null:
			errors.append("%s active skill is missing definition: %s" % [archetype_id, skill_id])
		elif String(item.archetype_id) != String(archetype_id):
			errors.append("%s active skill points back to %s" % [archetype_id, item.archetype_id])
	if DEFINITIONS.size() != FactoryCatalogScript.archetypes().size():
		errors.append("active skill catalog must contain exactly one definition per archetype")
	return errors
