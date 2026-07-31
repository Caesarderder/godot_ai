extends SceneTree

var failures: Array[String] = []
var accidental_presses := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(568, 320)
	var scroll := ScrollContainer.new()
	scroll.name = "MobileTouchProbe"
	scroll.position = Vector2(20, 20)
	scroll.size = Vector2(280, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(280, 900)
	scroll.add_child(content)
	for index in 12:
		var button := Button.new()
		button.text = "卡片 %d" % index
		button.custom_minimum_size = Vector2(280, 70)
		button.pressed.connect(func() -> void: accidental_presses += 1)
		content.add_child(button)
	await process_frame
	await process_frame

	_dispatch_touch(0, Vector2(140, 180), true)
	_dispatch_drag(0, Vector2(140, 100), Vector2(0, -80))
	_dispatch_drag(0, Vector2(140, 55), Vector2(0, -45))
	_dispatch_touch(0, Vector2(140, 55), false)
	await process_frame
	_check(scroll.scroll_vertical >= 100, "finger drag scrolls a list even when the gesture starts on a button")
	_check(accidental_presses == 0, "dragging a list does not activate the card under the finger")

	var before_wheel := scroll.scroll_vertical
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(140, 120)
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	Input.parse_input_event(wheel)
	await process_frame
	_check(scroll.scroll_vertical > before_wheel, "desktop mouse wheel remains supported")

	if failures.is_empty():
		print("MOBILE_SCROLL_INPUT_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error("MOBILE SCROLL INPUT TEST FAIL: %s" % failure)
	quit(1)


func _dispatch_touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	Input.parse_input_event(event)


func _dispatch_drag(index: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	Input.parse_input_event(event)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
