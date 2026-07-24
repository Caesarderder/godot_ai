class_name TemplateResponsiveShell
extends Control

signal mode_changed(is_narrow: bool)

@export_range(240.0, 2000.0, 1.0) var narrow_breakpoint: float = 600.0

var is_narrow: bool
var _initialized: bool = false


func _ready() -> void:
    resized.connect(refresh_mode)
    refresh_mode()


func refresh_mode() -> void:
    var next := size.x < narrow_breakpoint
    if not _initialized or next != is_narrow:
        _initialized = true
        is_narrow = next
        mode_changed.emit(is_narrow)
