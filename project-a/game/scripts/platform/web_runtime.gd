class_name WebRuntime
extends Node

signal focus_changed(has_focus: bool)
signal visibility_changed(is_visible: bool)
signal runtime_state_changed(state: Dictionary)
signal text_file_imported(text: String)
signal text_file_import_failed(error: String)

var is_visible: bool = true
var has_focus: bool = true
var _text_import_callback: JavaScriptObject
var _storage_probe_callback: JavaScriptObject
var storage_access_state: String = "native"


func _ready() -> void:
	if OS.has_feature("web"):
		storage_access_state = "checking"
		_probe_web_storage_access()


func platform_capabilities() -> Dictionary:
	var is_web := OS.has_feature("web")
	var engine_reports_persistence := (
		OS.is_userfs_persistent()
		if OS.has_method("is_userfs_persistent")
		else false
	)
	return {
		"is_web": is_web,
		"platform_name": OS.get_name(),
		"userfs_persistent": resolve_userfs_persistence(
			is_web,
			engine_reports_persistence
		),
		"storage_access_state": storage_access_state,
		"safe_area_supported": DisplayServer.has_method("get_display_safe_area"),
		"visibility_events": true,
		"focus_events": true,
		"javascript_bridge": is_web,
		"threaded_runtime": false,
	}


static func resolve_userfs_persistence(is_web_build: bool, engine_reports_persistence: bool) -> bool:
	# Godot's Web value can be true when IndexedDB writes work for this session, including
	# an isolated private context whose data disappears when that context closes. Do not
	# present that capability signal to players as confirmed long-term retention.
	return engine_reports_persistence and not is_web_build


func is_web() -> bool:
	return bool(platform_capabilities()["is_web"])


func _probe_web_storage_access() -> void:
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		set_storage_access_state("blocked")
		return
	_storage_probe_callback = JavaScriptBridge.create_callback(_on_storage_probe_completed)
	window.set("godotStorageProbeCallback", _storage_probe_callback)
	JavaScriptBridge.eval("""
		(() => {
			const finish = (value) => {
				const callback = window.godotStorageProbeCallback;
				if (typeof callback === "function") callback(value);
			};
			try {
				if (!globalThis.indexedDB) {
					finish("blocked");
					return;
				}
				const request = globalThis.indexedDB.open("/userfs");
				request.onerror = () => finish("blocked");
				request.onblocked = () => finish("blocked");
				request.onsuccess = () => {
					request.result.close();
					finish("session_available");
				};
			} catch (_error) {
				finish("blocked");
			}
		})()
	""", true)


func _on_storage_probe_completed(arguments: Array) -> void:
	if arguments.is_empty():
		set_storage_access_state("blocked")
		return
	set_storage_access_state(String(arguments[0]))


func set_storage_access_state(next_state: String) -> void:
	if next_state not in ["native", "checking", "session_available", "blocked"]:
		next_state = "blocked"
	if storage_access_state == next_state:
		return
	storage_access_state = next_state
	if _can_emit_runtime_state():
		runtime_state_changed.emit(runtime_state())


func download_text_file(filename: String, text: String) -> bool:
	if not is_web() or filename.is_empty():
		return false
	var encoded := Marshalls.raw_to_base64(text.to_utf8_buffer())
	var script := """
		(() => {
			const bytes = Uint8Array.from(atob(%s), c => c.charCodeAt(0));
			const url = URL.createObjectURL(new Blob([bytes], {type: "application/json;charset=utf-8"}));
			const anchor = document.createElement("a");
			anchor.href = url;
			anchor.download = %s;
			document.body.appendChild(anchor);
			anchor.click();
			anchor.remove();
			setTimeout(() => URL.revokeObjectURL(url), 1000);
			return true;
		})()
	""" % [JSON.stringify(encoded), JSON.stringify(filename)]
	return bool(JavaScriptBridge.eval(script, true))


func request_text_file_import() -> bool:
	if not is_web():
		return false
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return false
	_text_import_callback = JavaScriptBridge.create_callback(_on_text_file_import)
	window.set("godotSaveImportCallback", _text_import_callback)
	var script := """
		(() => {
			const input = document.createElement("input");
			input.type = "file";
			input.accept = ".json,application/json";
			input.style.display = "none";
			input.addEventListener("change", () => {
				const file = input.files && input.files[0];
				if (!file) {
					input.remove();
					return;
				}
				if (file.size > 2097152) {
					window.godotSaveImportCallback("__ERROR__:SAVE_TOO_LARGE");
					input.remove();
					return;
				}
				const reader = new FileReader();
				reader.onload = () => {
					window.godotSaveImportCallback(String(reader.result || ""));
					input.remove();
				};
				reader.onerror = () => {
					window.godotSaveImportCallback("__ERROR__:SAVE_READ_FAILED");
					input.remove();
				};
				reader.readAsText(file, "utf-8");
			}, {once: true});
			document.body.appendChild(input);
			input.click();
			return true;
		})()
	"""
	return bool(JavaScriptBridge.eval(script, true))


func _on_text_file_import(arguments: Array) -> void:
	if arguments.is_empty():
		text_file_import_failed.emit("SAVE_IMPORT_EMPTY")
		return
	var text := String(arguments[0])
	if text.begins_with("__ERROR__:"):
		text_file_import_failed.emit(text.trim_prefix("__ERROR__:"))
		return
	text_file_imported.emit(text)


func runtime_state() -> Dictionary:
	return {
		"is_web": is_web(),
		"is_visible": is_visible,
		"has_focus": has_focus,
		"is_interactive": is_visible and has_focus,
		"storage_access_state": storage_access_state,
	}


func set_visibility_state(next_visible: bool) -> void:
	if is_visible == next_visible:
		return
	is_visible = next_visible
	if not _can_emit_runtime_state():
		return
	visibility_changed.emit(is_visible)
	runtime_state_changed.emit(runtime_state())


func set_focus_state(next_focus: bool) -> void:
	if has_focus == next_focus:
		return
	has_focus = next_focus
	if not _can_emit_runtime_state():
		return
	focus_changed.emit(has_focus)
	runtime_state_changed.emit(runtime_state())


func _can_emit_runtime_state() -> bool:
	if not is_inside_tree():
		return false
	var parent := get_parent()
	return parent == null or parent.is_inside_tree()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			set_focus_state(true)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			set_focus_state(false)
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			set_focus_state(true)
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			set_focus_state(false)
		NOTIFICATION_WM_CLOSE_REQUEST:
			set_visibility_state(false)
		_:
			pass
