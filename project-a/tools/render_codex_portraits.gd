extends SceneTree

const ToiletUnitViewScript := preload(
	"res://game/scripts/presentation_3d/toilet_unit_view.gd"
)
const FactoryCatalogScript := preload(
	"res://game/scripts/domain/factory/factory_catalog.gd"
)

const OUTPUT_DIR := "res://assets/ui/codex"
const SIZE := Vector2i(192, 192)
const EXTERNAL_MODEL_IDS := [
	"assault", "sonic", "rocket", "bomber",
	"armored", "saw", "repair", "parasite",
]


func _init() -> void:
	call_deferred("_render_all")


func _render_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	RenderingServer.set_default_clear_color(Color("#07131b"))
	var entries: Array[Dictionary] = [{
		"archetype_id": "gman",
		"display_name": "Gman",
		"class_id": "arcanist",
	}]
	for recipe_value in FactoryCatalogScript.recipes():
		var recipe := recipe_value as Dictionary
		entries.append({
			"archetype_id": String(recipe.get("archetype_id", "")),
			"display_name": String(recipe.get("display_name", "")),
			"class_id": String(recipe.get("class_id", "fighter")),
		})
	for entry in entries:
		if not await _render_portrait(entry):
			push_error("CODEX_PORTRAIT_RENDER_FAIL: %s" % String(entry["archetype_id"]))
			quit(1)
			return
	print("CODEX_PORTRAITS_OK: %d WebP portraits" % entries.size())
	quit(0)


func _render_portrait(entry: Dictionary) -> bool:
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.transparent_bg = false
	root.add_child(viewport)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#07131b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#5aaec0")
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	viewport.add_child(environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -28, 0)
	key.light_color = Color("#f4d7aa")
	key.light_energy = 1.35
	key.shadow_enabled = true
	viewport.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-26, 152, 0)
	rim.light_color = Color("#52d7df")
	rim.light_energy = 1.05
	viewport.add_child(rim)

	var camera := Camera3D.new()
	camera.fov = 34.0
	camera.look_at_from_position(Vector3(3.0, 2.45, -5.2), Vector3(0.0, 1.08, 0.0))
	viewport.add_child(camera)
	camera.current = true

	var view := ToiletUnitViewScript.new()
	viewport.add_child(view)
	view.setup({
		"unit_id": StringName("codex_%s" % String(entry["archetype_id"])),
		"team": 0,
		"slot": 1,
		"lane": 1,
		"road_position": 400,
		"hp": 100,
		"max_hp": 100,
		"alive": true,
		"temporary": true,
		"class_id": String(entry["class_id"]),
		"archetype_id": String(entry["archetype_id"]),
		"display_name": String(entry["display_name"]),
		"elite": false,
	})
	view.position = Vector3.ZERO
	if String(entry["archetype_id"]) in EXTERNAL_MODEL_IDS:
		view.rotation_degrees.y = 180.0
	view.set_reduced_motion(true)
	var body := view.get_node_or_null("BodyPivot")
	if body != null:
		var name_label := body.get_node_or_null("NameLabel") as Label3D
		var health_label := body.get_node_or_null("HealthLabel") as Label3D
		if name_label != null:
			name_label.hide()
		if health_label != null:
			health_label.hide()

	for _frame in 5:
		await process_frame
	var image := viewport.get_texture().get_image()
	image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	var path := "%s/%s.webp" % [OUTPUT_DIR, String(entry["archetype_id"])]
	var result := image.save_webp(path, false, 0.82)
	viewport.queue_free()
	await process_frame
	return result == OK
