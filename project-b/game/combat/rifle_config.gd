class_name RifleConfig
extends Resource

@export_range(1, 200, 1) var damage: int = 34
@export_range(1, 120, 1) var magazine_size: int = 30
@export_range(0, 500, 1) var starting_reserve: int = 120
@export_range(0.03, 2.0, 0.01) var seconds_per_shot: float = 0.105
@export_range(0.1, 10.0, 0.05) var reload_seconds: float = 1.45
@export_range(5.0, 500.0, 1.0) var range_meters: float = 180.0
