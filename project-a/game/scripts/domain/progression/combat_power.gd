class_name CombatPower
extends RefCounted

const HeroProgressionScript := preload("res://game/scripts/domain/progression/hero_progression.gd")

static func hero_power(hero: RefCounted) -> int:
	if hero == null:
		return 0
	var stats := HeroProgressionScript.derived_battle_stats(hero)
	return stats_power(
		int(stats["hp"]),
		int(stats["attack"]),
		int(stats["defense"]),
		int(stats["speed_milli"]),
		int(stats["crit_bp"])
	)


static func projected_hero_power_for_star(hero: RefCounted, target_star: int) -> int:
	if hero == null:
		return 0
	var projected: RefCounted = hero.deep_clone()
	projected.star = clampi(target_star, int(hero.star), 3)
	return hero_power(projected)


static func snapshot_power(snapshot: Dictionary) -> int:
	return stats_power(
		int(snapshot.get("max_hp", 0)),
		int(snapshot.get("attack", 0)),
		int(snapshot.get("defense", 0)),
		int(snapshot.get("speed_milli", 80000)),
		int(snapshot.get("crit_bp", 1000))
	)


static func stats_power(
	max_hp: int,
	attack: int,
	defense: int,
	speed_milli: int,
	crit_bp: int
) -> int:
	return (
		maxi(0, max_hp) * 3
		+ maxi(0, attack) * 20
		+ maxi(0, defense) * 10
		+ maxi(0, speed_milli) / 500
		+ maxi(0, crit_bp) / 10
	)


static func formation_power(state: RefCounted) -> int:
	if state == null:
		return 0
	var total: int = 0
	for hero_id in state.formation.hero_ids():
		total += hero_power(state.hero_by_id(String(hero_id)))
	return total


static func snapshots_power(snapshots: Array[Dictionary]) -> int:
	var total: int = 0
	for snapshot in snapshots:
		total += snapshot_power(snapshot)
	return total


static func readiness(team_power: int, recommended_power: int, minimum_power: int) -> String:
	if team_power >= recommended_power:
		return "ready"
	if team_power >= minimum_power:
		return "challenge"
	return "underpowered"


static func readiness_label(readiness_id: String) -> String:
	match readiness_id:
		"ready":
			return "战力充足"
		"challenge":
			return "可挑战"
		_:
			return "建议成长"
