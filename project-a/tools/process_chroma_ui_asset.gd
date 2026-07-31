extends SceneTree


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		push_error("usage: -- <input> <output.webp> <square-size>")
		quit(2)
		return
	var source := Image.new()
	var load_error := source.load(args[0])
	if load_error != OK:
		push_error("cannot load chroma source: %s" % error_string(load_error))
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	# Generated chroma sources are often color-managed or lightly compressed,
	# so sample the real corner instead of assuming literal #ff00ff bytes.
	var key := source.get_pixel(0, 0)
	for y in source.get_height():
		for x in source.get_width():
			var pixel := source.get_pixel(x, y)
			var distance := Vector3(pixel.r, pixel.g, pixel.b).distance_to(
				Vector3(key.r, key.g, key.b)
			)
			var alpha := smoothstep(0.035, 0.34, distance)
			if alpha < 0.99:
				# Despill the keyed channel before premultiplied filtering.
				pixel.g = minf(pixel.g, maxf(pixel.r, pixel.b) + 0.04)
				pixel.b = minf(pixel.b, pixel.r + 0.12)
			pixel.a = alpha
			source.set_pixel(x, y, pixel)
	var target_size := maxi(32, int(args[2]))
	source.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
	# Lanczos filtering can spread a barely-visible keyed RGB value across the
	# transparent field. Hard-clear that low-alpha haze so dark mobile panels do
	# not reveal a magenta rectangle around the character.
	for y in source.get_height():
		for x in source.get_width():
			var filtered := source.get_pixel(x, y)
			if filtered.a < 0.16:
				filtered = Color(0.0, 0.0, 0.0, 0.0)
				source.set_pixel(x, y, filtered)
	var save_error := source.save_webp(args[1], true, 0.86)
	if save_error != OK:
		push_error("cannot save UI WebP: %s" % error_string(save_error))
		quit(1)
		return
	print("CHROMA_UI_ASSET_OK: %s corner_alpha=%.3f" % [args[1], source.get_pixel(0, 0).a])
	quit(0)
