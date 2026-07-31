extends Node

const DRAG_DEADZONE := 10.0

var _touch_origins: Dictionary = {}
var _touch_distance: Dictionary = {}
var _touch_owners: Dictionary = {}
var _scroll_targets: Array[ScrollContainer] = []


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
	if _can_scroll_horizontally(owner) and (
		absf(distance.x) > absf(distance.y) or not _can_scroll_vertically(owner)
	):
		owner.scroll_horizontal -= roundi(event.relative.x)
	elif _can_scroll_vertically(owner):
		owner.scroll_vertical -= roundi(event.relative.y)
	get_viewport().set_input_as_handled()


func _best_target(position: Vector2, horizontal: bool) -> ScrollContainer:
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
