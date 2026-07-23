class_name M3StageCatalog
extends RefCounted


static func scenarios() -> Dictionary:
	return {
		"stage-1-1": {
			"stage_id": "stage-1-1",
			"content_hash": "3268fb8f9d504514f32bb013d9d5f1c1fcc83aba45b6bd535e7ef03208f0ed4b",
			"stage_snapshot_hash": "9e7fb1ca6f5688f347a2bc342a00058666cf0528235775337635fcf6cb343f5e",
			"carry_speed": 300_000,
			"enemy_snapshot": {"attack": 1000, "hp": 50, "speed": 200_000},
			"hero_recipe_cutoffs": [
				{"attack": 100, "minimum_roll": 0},
				{"attack": 1, "minimum_roll": 975},
			],
			"intervention": null,
			"thresholds": {"win_rate_min_bp": 9500, "win_rate_max_bp": 10000},
		},
		"stage-1-2": {
			"stage_id": "stage-1-2",
			"content_hash": "3268fb8f9d504514f32bb013d9d5f1c1fcc83aba45b6bd535e7ef03208f0ed4b",
			"stage_snapshot_hash": "5dc421a209943086342cf579d25ef51744fd00e0ccfa48e14926e34522b5800b",
			"carry_speed": 300_000,
			"enemy_snapshot": {"attack": 1000, "hp": 50, "speed": 200_000},
			"hero_recipe_cutoffs": [
				{"attack": 100, "minimum_roll": 0},
				{"attack": 1, "minimum_roll": 875},
			],
			"intervention": null,
			"thresholds": {"win_rate_min_bp": 8000, "win_rate_max_bp": 9500},
		},
		"stage-1-3": {
			"stage_id": "stage-1-3",
			"content_hash": "3268fb8f9d504514f32bb013d9d5f1c1fcc83aba45b6bd535e7ef03208f0ed4b",
			"stage_snapshot_hash": "d2b03a4d8ba42a205cff3e3f65e4ed182ce979424cfb23e422c081edd9ccfa6b",
			"carry_speed": 100_000,
			"enemy_snapshot": {"attack": 10, "hp": 150, "speed": 100_000},
			"hero_recipe_cutoffs": [
				{"attack": 200, "minimum_roll": 0},
				{"attack": 100, "minimum_roll": 220},
				{"attack": 1, "minimum_roll": 620},
			],
			"intervention": {
				"type": "set_formation",
				"slots_from_roster_indices": [1, 0, 2, 3],
			},
			"thresholds": {"before_min_bp": 1500, "before_max_bp": 3000, "delta_min_bp": 3000},
		},
		"stage-1-4": {
			"stage_id": "stage-1-4",
			"content_hash": "3268fb8f9d504514f32bb013d9d5f1c1fcc83aba45b6bd535e7ef03208f0ed4b",
			"stage_snapshot_hash": "0ced5e2185428be286b8d387954128df486fcc3949a8645e8352848bb7513dc2",
			"carry_speed": 100_000,
			"enemy_snapshot": {"attack": 10, "hp": 150, "speed": 100_000},
			"hero_recipe_cutoffs": [
				{"attack": 200, "minimum_roll": 0},
				{"attack": 100, "minimum_roll": 420},
				{"attack": 1, "minimum_roll": 820},
			],
			"intervention": {
				"type": "set_formation",
				"slots_from_roster_indices": [1, 0, 2, 3],
			},
			"thresholds": {"before_min_bp": 3500, "before_max_bp": 5000, "after_min_bp": 7500, "after_max_bp": 9000},
		},
		"stage-1-5": {
			"stage_id": "stage-1-5",
			"content_hash": "3268fb8f9d504514f32bb013d9d5f1c1fcc83aba45b6bd535e7ef03208f0ed4b",
			"stage_snapshot_hash": "e66affca1dac382c6e3391f45a72a1a5dbb087f36019a04c86554a876698fa5b",
			"carry_speed": 100_000,
			"enemy_snapshot": {"attack": 10, "hp": 150, "speed": 100_000},
			"hero_recipe_cutoffs": [
				{"attack": 200, "minimum_roll": 0},
				{"attack": 100, "minimum_roll": 150},
				{"attack": 1, "minimum_roll": 550},
			],
			"intervention": {
				"type": "equip_item",
				"item_id": "guaranteed_rare_id",
				"equipment_bonus": 100,
			},
			"thresholds": {"before_min_bp": 1000, "before_max_bp": 2500, "delta_min_bp": 3000},
		},
	}
