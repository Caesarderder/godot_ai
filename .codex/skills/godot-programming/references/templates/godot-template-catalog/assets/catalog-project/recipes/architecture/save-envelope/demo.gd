extends Node

var encoded: Dictionary


func _ready() -> void:
    encoded = TemplateSaveEnvelope.encode({"score": 10})
