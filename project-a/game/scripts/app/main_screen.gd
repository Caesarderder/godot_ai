extends Control

@onready var _status: Label = $SafeArea/Content/Status
@onready var _persistence: Label = $SafeArea/Content/StateCard/StateContent/Persistence
@onready var _save_id: Label = $SafeArea/Content/StateCard/StateContent/SaveId
@onready var _revision: Label = $SafeArea/Content/StateCard/StateContent/Revision
@onready var _offline_credit: Label = $SafeArea/Content/StateCard/StateContent/OfflineCredit
@onready var _refresh_button: Button = $SafeArea/Content/RefreshButton

var _game: Object


func _ready() -> void:
	_refresh_button.pressed.connect(_refresh_state)
	configure_game(get_tree().root.get_node_or_null("Game"))


func configure_game(game_port: Object) -> void:
	var ready_callable := Callable(self, "_refresh_state")
	if _game != null and _game.has_signal("game_ready") and _game.is_connected(
		"game_ready", ready_callable
	):
		_game.disconnect("game_ready", ready_callable)
	_game = game_port
	if _game != null and _game.has_signal("game_ready") and not _game.is_connected(
		"game_ready", ready_callable
	):
		_game.connect("game_ready", ready_callable)
	_refresh_state()


func _refresh_state() -> void:
	if _game == null or not _game.has_method("get_state"):
		_show_waiting_state()
		return
	var state: Dictionary = _game.get_state()
	if state.is_empty():
		_show_waiting_state()
		return
	_status.text = "M1 状态已加载"
	_persistence.text = "持久化：已安装快照"
	var identifier := str(state.get("save_id", ""))
	_save_id.text = "存档：%s" % (
		identifier.left(8) + "…" if identifier.length() > 8 else identifier
	)
	_revision.text = "状态版本：r%d" % int(state.get("revision", 0))
	var economy: Dictionary = state.get("economy", { })
	_offline_credit.text = "累计离线收益：%s" % _format_duration(
		int(economy.get("offline_seconds", 0))
	)


func _show_waiting_state() -> void:
	_status.text = "M1 正在初始化"
	_persistence.text = "持久化：等待 Game 就绪"
	_save_id.text = "存档：—"
	_revision.text = "状态版本：—"
	_offline_credit.text = "累计离线收益：—"


func _format_duration(total_seconds: int) -> String:
	var clamped := maxi(total_seconds, 0)
	var hours := floori(float(clamped) / 3600.0)
	var minutes := floori(float(clamped % 3600) / 60.0)
	var seconds := clamped % 60
	return "%d小时 %d分 %d秒" % [hours, minutes, seconds]
