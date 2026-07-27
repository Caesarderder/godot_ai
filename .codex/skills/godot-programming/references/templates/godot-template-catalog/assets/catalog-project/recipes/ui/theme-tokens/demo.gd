extends Control

@export var tokens: TemplateThemeTokens


func _ready() -> void:
    theme = TemplateThemeFactory.build(tokens)
