extends GutTest

const HeroGeneratorScript := preload("res://game/scripts/domain/heroes/hero_generator.gd")
const HeroProgressionScript := preload("res://game/scripts/domain/heroes/hero_progression.gd")


func test_level_thresholds_and_l5_xp_are_clamped() -> void:
	var hero: Dictionary = HeroGeneratorScript.generate_roster(7, 1)[0]
	for pair: Array in [[0, 1], [40, 2], [100, 3], [200, 4], [320, 5]]:
		var trained: Dictionary = HeroProgressionScript.add_xp(hero, pair[0])
		assert_eq(trained.level, pair[1])
	var capped: Dictionary = HeroProgressionScript.add_xp(hero, 99_999)
	assert_eq(capped.level, 5)
	assert_eq(capped.xp, 320)


func test_incremental_and_batch_training_preserve_fixed_point_growth() -> void:
	var hero: Dictionary = HeroGeneratorScript.generate_roster(19, 1)[0]
	var incremental: Dictionary = hero
	for amount: int in [40, 60, 100, 120]:
		incremental = HeroProgressionScript.add_xp(incremental, amount)
	var batch: Dictionary = HeroProgressionScript.add_xp(hero, 320)
	assert_eq(incremental, batch)
	assert_ne(batch.stats, hero.stats)
	assert_eq(hero.level, 1, "progression must not mutate its input")

