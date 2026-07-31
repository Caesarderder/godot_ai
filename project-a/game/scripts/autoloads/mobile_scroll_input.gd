extends Node

const DRAG_DEADZONE := 10.0

var _touch_origins: Dictionary = {}
var _touch_distance: Dictionary = {}
var _touch_owners: Dictionary = {}
var _scroll_targets: Array[ScrollContainer] = []
var _mouse_origin := Vector2.ZERO
var _mouse_distance := Vector2.ZERO
var _mouse_owner: ScrollContainer
var _mouse_pressed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_register_if_scroll)
	for node in get_tree().get_nodes_in_group("mobile_scroll_target"):
		_register_if_scroll(node)
	_scan_existing(get_tree().root)


func _scan_existing(node: Node) -> void:
	_register_if_scroll(node)
	for child in node.get_children():
		_scan_existing(child)


func _register_if_scroll(node: Node) -> void:
	if not node is ScrollContainer:
		return
	var scroll := node as ScrollContainer
	if scroll in _scroll_targets:
		return
	_scroll_targets.append(scroll)
	scroll.tree_exiting.connect(_unregister.bind(scroll), CONNECT_ONE_SHOT)


func _unregister(scroll: ScrollContainer) -> void:
	_scroll_targets.erase(scroll)
	for touch_id in _touch_owners.keys():
		if _touch_owners[touch_id] == scroll:
			_touch_owners.erase(touch_id)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_drag(event as InputEventMouseMotion)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_pressed = true
			_mouse_origin = event.position
			_mouse_distance = Vector2.ZERO
			_mouse_owner = null
		elif _mouse_pressed:
			_mouse_pressed = false
			var claimed := _mouse_owner != null
			_mouse_owner = null
			if claimed:
				get_viewport().set_input_as_handled()
		return
	_handle_mouse_wheel(event)


func _handle_mouse_drag(event: InputEventMouseMotion) -> void:
	if not _mouse_pressed or not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		return
	_mouse_distance += event.relative
	if _mouse_owner == null and _mouse_distance.length() >= DRAG_DEADZONE:
		_mouse_owner = _best_target(
			_mouse_origin,
			absf(_mouse_distance.x) > absf(_mouse_distance.y)
		)
	if _mouse_owner == null:
		return
	_scroll_by_drag(_mouse_owner, event.relative, _mouse_distance)
	get_viewport().set_input_as_handled()


func _handle_mouse_wheel(event: InputEventMouseButton) -> void:
	if not event.pressed or event.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return
	var owner := _best_wheel_target(event.position)
	if owner == null:
		return
	var direction := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
	if _can_scroll_vertically(owner):
		owner.scroll_vertical += direction * 72
	elif _can_scroll_horizontally(owner):
		owner.scroll_horizontal += direction * 72
	get_viewport().set_input_as_handled()


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_origins[event.index] = event.position
		_touch_distance[event.index] = Vector2.ZERO
		return
	var claimed := _touch_owners.erase(event.index)
	_touch_origins.erase(event.index)
	_touch_distance.erase(event.index)
	if claimed:
		get_viewport().set_input_as_handled()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _touch_origins.has(event.index):
		return
	var distance := (_touch_distance.get(event.index, Vector2.ZERO) as Vector2) + event.relative
	_touch_distance[event.index] = distance
	var owner := _touch_owners.get(event.index) as ScrollContainer
	if owner == null and distance.length() >= DRAG_DEADZONE:
		owner = _best_target(
			_touch_origins[event.index] as Vector2,
			absf(distance.x) > absf(distance.y)
		)
		if owner != null:
			_touch_owners[event.index] = owner
	if owner == null:
		return
	_scroll_by_drag(owner, event.relative, distance)
	get_viewport().set_input_as_handled()


func _scroll_by_drag(owner: ScrollContainer, relative: Vector2, distance: Vector2) -> void:
	if _can_scroll_horizontally(owner) and (
		absf(distance.x) > absf(distance.y) or not _can_scroll_vertically(owner)
	):
		owner.scroll_horizontal -= roundi(relative.x)
	elif _can_scroll_vertically(owner):
		owner.scroll_vertical -= roundi(relative.y)


func _best_target(position: Vector2, horizontal: bool) -> ScrollContainer:
	var preferred := _smallest_target_at(position, horizontal)
	if preferred != null:
		return preferred
	return _smallest_target_at(position, not horizontal)


func _best_wheel_target(position: Vector2) -> ScrollContainer:
	var vertical := _smallest_target_at(position, false)
	if vertical != null:
		return vertical
	return _smallest_target_at(position, true)


func _smallest_target_at(position: Vector2, horizontal: bool) -> ScrollContainer:
	var winner: ScrollContainer
	var winner_area := INF
	for scroll in _scroll_targets:
		if not is_instance_valid(scroll) or not scroll.is_visible_in_tree():
			continue
		if not scroll.get_global_rect().has_point(position):
			continue
		if horizontal and not _can_scroll_horizontally(scroll):
			continue
		if not horizontal and not _can_scroll_vertically(scroll):
			continue
		var area := scroll.size.x * scroll.size.y
		if area < winner_area:
			winner = scroll
			winner_area = area
	return winner


func _can_scroll_horizontally(scroll: ScrollContainer) -> bool:
	if scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return false
	var bar := scroll.get_h_scroll_bar()
	return bar != null and bar.max_value > bar.page + 1.0


func _can_scroll_vertically(scroll: ScrollContainer) -> bool:
	if scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return false
	var bar := scroll.get_v_scroll_bar()
	return bar != null and bar.max_value > bar.page + 1.0
