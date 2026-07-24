class_name TemplateComponentGallery
extends Control


func _ready() -> void:
    var first := get_node_or_null("Scroll/Layout/Buttons/Normal") as Button
    if first != null:
        first.grab_focus.call_deferred()
