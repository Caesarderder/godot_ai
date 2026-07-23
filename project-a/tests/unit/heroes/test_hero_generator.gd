extends GutTest

const HeroGeneratorScript := preload("res://game/scripts/domain/heroes/hero_generator.gd")


func test_fixed_seed_reproduces_eight_distinct_heroes() -> void:
	var first: Array[Dictionary] = HeroGeneratorScript.generate_roster(0x13579BDF)
	var second: Array[Dictionary] = HeroGeneratorScript.generate_roster(0x13579BDF)
	assert_eq(first, second)
	assert_eq(first.size(), 8)
	var ids: Array[String] = []
	for hero: Dictionary in first:
		ids.append(hero.id)
	assert_eq(ids.duplicate().reduce(func(unique: Array, id: String) -> Array:
		if not unique.has(id): unique.append(id)
		return unique
	, []).size(), 8)


func test_roster_exposes_four_classes_and_readable_difference_fields() -> void:
	var roster: Array[Dictionary] = HeroGeneratorScript.generate_roster(12345)
	var classes: Array[String] = []
	var aptitudes: Array[String] = []
	var traits: Array[String] = []
	for hero: Dictionary in roster:
		if not classes.has(hero.class_id):
			classes.append(hero.class_id)
		if not aptitudes.has(hero.aptitude):
			aptitudes.append(hero.aptitude)
		if not traits.has(hero.trait):
			traits.append(hero.trait)
		assert_true(["C", "B", "A", "S"].has(hero.aptitude))
		assert_false(str(hero.trait).is_empty())
		assert_eq(hero.stats.size(), 4)
	assert_eq(classes.size(), 4)
	assert_eq(aptitudes.size(), 4)
	assert_eq(traits.size(), 8)
