extends SceneTree

## A bounded repeatable stress smoke. It records measured frame deltas; it does not
## claim target-hardware performance or replace an external profiler.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://game/moba_game.tscn") as PackedScene
	if packed == null:
		push_error("Cannot load MOBA scene"); quit(1); return
	var game: Variant = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.debug_action_peak()
	var samples: Array[float] = []
	for _index in 180:
		var before_usec: int = Time.get_ticks_usec()
		await process_frame
		var elapsed_usec: int = Time.get_ticks_usec() - before_usec
		samples.append(float(elapsed_usec) / 1000.0)
	samples.sort()
	var p50: float = samples[int(samples.size() * 0.50)]
	var p95: float = samples[int(samples.size() * 0.95)]
	var p99: float = samples[int(samples.size() * 0.99)]
	var worst: float = samples.back()
	print("MOBA_STRESS_FRAME_MS p50=%.3f p95=%.3f p99=%.3f worst=%.3f samples=%d" % [p50, p95, p99, worst, samples.size()])
	quit(0)
