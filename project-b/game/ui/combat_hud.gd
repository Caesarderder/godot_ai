class_name CombatHud
extends CanvasLayer

@onready var health_fill: ColorRect = %HealthFill
@onready var health_value: Label = %HealthValue
@onready var ammo_value: Label = %AmmoValue
@onready var reserve_value: Label = %ReserveValue
@onready var objective_value: Label = %ObjectiveValue
@onready var status_line: Label = %StatusLine
@onready var target_status: Label = %TargetStatus
@onready var hit_marker: Label = %HitMarker
@onready var damage_vignette: ColorRect = %DamageVignette
@onready var critical_frame: Control = %CriticalFrame
@onready var reload_progress: ProgressBar = %ReloadProgress
@onready var outcome_panel: Control = %OutcomePanel
@onready var outcome_title: Label = %OutcomeTitle
@onready var outcome_summary: Label = %OutcomeSummary

var _hit_tween: Tween
var _damage_tween: Tween
var _reload_tween: Tween


func _ready() -> void:
	reset_hud()


func set_player_health(current: int, maximum: int) -> void:
	var ratio := float(current) / float(maxi(1, maximum))
	health_fill.scale.x = clampf(ratio, 0.0, 1.0)
	health_value.text = "%03d" % current
	if ratio <= 0.2:
		health_fill.color = Color("#ff3d55")
	elif ratio <= 0.45:
		health_fill.color = Color("#ff9e3d")
	else:
		health_fill.color = Color("#36d7ff")
	critical_frame.visible = ratio <= 0.65 and current > 0
	critical_frame.modulate.a = 1.0 if ratio <= 0.2 else 0.5


func set_ammo(ammo: int, reserve: int, reloading: bool) -> void:
	ammo_value.text = "%02d" % ammo
	reserve_value.text = "/ %03d" % reserve
	if reloading:
		status_line.text = "RELOADING  •  KEEP COVER"
		ammo_value.modulate = Color("#ff9e3d")
		reload_progress.visible = true
		reload_progress.value = 0.0
		if _reload_tween != null and _reload_tween.is_valid():
			_reload_tween.kill()
		_reload_tween = create_tween()
		_reload_tween.tween_property(reload_progress, "value", 100.0, 1.45)
	elif ammo <= 6:
		status_line.text = "LOW AMMO  •  R TO RELOAD"
		ammo_value.modulate = Color("#ff9e3d")
		reload_progress.visible = false
	else:
		status_line.text = "NIGHTGLASS // LIVE"
		ammo_value.modulate = Color("#eaf6ff")
		reload_progress.visible = false


func set_objective(remaining: int, total: int) -> void:
	objective_value.text = "CLEAR SENTRIES  %d / %d" % [total - remaining, total]
	if remaining == 1:
		objective_value.modulate = Color("#ff9e3d")
	else:
		objective_value.modulate = Color("#eaf6ff")


func set_target_health(actor_id: StringName, current: int, maximum: int) -> void:
	if current <= 0:
		target_status.text = "%s  //  NEUTRALIZED" % String(actor_id).to_upper()
		target_status.modulate = Color("#ff9e3d")
		return
	target_status.text = "%s  //  %03d%%" % [
		String(actor_id).to_upper(),
		int(round(float(current) / float(maxi(1, maximum)) * 100.0)),
	]
	target_status.modulate = Color("#eaf6ff")


func show_hit(lethal: bool) -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	hit_marker.text = "◆" if lethal else "×"
	hit_marker.modulate = Color("#ff9e3d") if lethal else Color("#eaf6ff")
	hit_marker.scale = Vector2(1.5, 1.5)
	hit_marker.visible = true
	_hit_tween = create_tween()
	_hit_tween.tween_property(hit_marker, "scale", Vector2.ONE, 0.08)
	_hit_tween.tween_interval(0.08 if lethal else 0.04)
	_hit_tween.tween_property(hit_marker, "modulate:a", 0.0, 0.12)
	_hit_tween.tween_callback(func() -> void: hit_marker.visible = false)


func show_damage() -> void:
	if _damage_tween != null and _damage_tween.is_valid():
		_damage_tween.kill()
	damage_vignette.modulate.a = 0.62
	_damage_tween = create_tween()
	_damage_tween.tween_property(damage_vignette, "modulate:a", 0.0, 0.24)


func show_outcome(victory: bool, summary: Dictionary) -> void:
	outcome_panel.visible = true
	outcome_title.text = "BLACKSITE SECURED" if victory else "OPERATOR DOWN"
	outcome_title.modulate = Color.WHITE
	outcome_title.add_theme_color_override(
		"font_color",
		Color("#36d7ff") if victory else Color("#ff5570")
	)
	var cause_line := ""
	if not victory:
		cause_line = "LAST HIT  %s\n" % String(summary.get("cause", "UNKNOWN THREAT"))
	outcome_summary.text = (
		"TIME  %05.1fs     ACCURACY  %02d%%\n"
		+ "HOSTILES  %d     SHOTS  %d\n\n"
		+ cause_line
		+ "PRESS ENTER TO REDEPLOY"
	) % [
		float(summary.get("elapsed_seconds", 0.0)),
		int(summary.get("accuracy_percent", 0)),
		int(summary.get("enemies_down", 0)),
		int(summary.get("shots_fired", 0)),
	]
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func reset_hud() -> void:
	if not is_node_ready():
		return
	outcome_panel.visible = false
	hit_marker.visible = false
	hit_marker.modulate.a = 1.0
	damage_vignette.modulate.a = 0.0
	critical_frame.visible = false
	reload_progress.visible = false
	status_line.text = "NIGHTGLASS // LIVE"
	target_status.text = "TARGET FEED  //  SEARCHING"
	target_status.modulate = Color("#7aaabd")
	set_player_health(100, 100)
	set_ammo(30, 120, false)
	set_objective(4, 4)
