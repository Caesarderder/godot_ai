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
	await process_frame
	_dispatch_drag(0, Vector2(140, 100), Vector2(0, -80))
	await process_frame
	_dispatch_drag(0, Vector2(140, 55), Vector2(0, -45))
	await process_frame
	_dispatch_touch(0, Vector2(140, 55), false)
	await process_frame
	_check(scroll.scroll_vertical >= 100, "finger drag scrolls a list even when the gesture starts on a button")
	_check(accidental_presses == 0, "dragging a list does not activate the card under the finger")

	var before_wheel := scroll.scroll_vertical
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(140, 120)
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	(root.get_node("MobileScrollInput") as Node).call("_input", wheel)
	await process_frame
	_check(scroll.scroll_vertical >= before_wheel + 70, "desktop wheel deterministically scrolls a vertical list")

	scroll.scroll_vertical = 0
	_dispatch_touch(2, Vector2(140, 180), true)
	await process_frame
	_dispatch_drag(2, Vector2(164, 120), Vector2(24, -60))
	await process_frame
	_dispatch_touch(2, Vector2(164, 120), false)
	await process_frame
	_check(scroll.scroll_vertical >= 50, "a slightly diagonal phone swipe still claims the vertical list")

	var strip := ScrollContainer.new()
	strip.name = "MobileHorizontalProbe"
	strip.position = Vector2(310, 20)
	strip.size = Vector2(238, 110)
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(strip)
	var strip_content := HBoxContainer.new()
	strip_content.custom_minimum_size = Vector2(720, 110)
	strip.add_child(strip_content)
	for index in 6:
		var card := Button.new()
		card.text = "建筑 %d" % index
		card.custom_minimum_size = Vector2(116, 100)
		strip_content.add_child(card)
	await process_frame
	await process_frame
	_dispatch_touch(1, Vector2(500, 75), true)
	await process_frame
	_dispatch_drag(1, Vector2(410, 75), Vector2(-90, 0))
	await process_frame
	_dispatch_touch(1, Vector2(410, 75), false)
	await process_frame
	_check(strip.scroll_horizontal >= 80, "finger drag scrolls horizontal building and character strips")
	strip.scroll_horizontal = 0
	_dispatch_touch(3, Vector2(500, 75), true)
	await process_frame
	_dispatch_drag(3, Vector2(430, 99), Vector2(-70, 24))
	await process_frame
	_dispatch_touch(3, Vector2(430, 99), false)
	await process_frame
	_check(strip.scroll_horizontal >= 60, "a slightly diagonal phone swipe still claims the horizontal runway")
	var before_horizontal_wheel := strip.scroll_horizontal
	var horizontal_wheel := InputEventMouseButton.new()
	horizontal_wheel.position = Vector2(420, 75)
	horizontal_wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	horizontal_wheel.pressed = true
	(root.get_node("MobileScrollInput") as Node).call("_input", horizontal_wheel)
	await process_frame
	_check(strip.scroll_horizontal > before_horizontal_wheel, "desktop wheel scrolls a hovered horizontal runway")
	strip.scroll_horizontal = 0
	_dispatch_mouse_button(Vector2(500, 75), true)
	await process_frame
	_dispatch_mouse_drag(Vector2(410, 75), Vector2(-90, 0))
	await process_frame
	_dispatch_mouse_button(Vector2(410, 75), false)
	await process_frame
	_check(strip.scroll_horizontal >= 80, "desktop left-button drag mirrors a phone swipe")

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
	(root.get_node("MobileScrollInput") as Node).call("_input", event)


func _dispatch_drag(index: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	(root.get_node("MobileScrollInput") as Node).call("_input", event)


func _dispatch_mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	(root.get_node("MobileScrollInput") as Node).call("_input", event)


func _dispatch_mouse_drag(position: Vector2, relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	(root.get_node("MobileScrollInput") as Node).call("_input", event)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
