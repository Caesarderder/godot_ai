class_name TemplateThemeFactory
extends RefCounted


static func build(tokens: TemplateThemeTokens) -> Theme:
    assert(tokens != null, "TemplateThemeFactory requires tokens")
    var theme := Theme.new()
    theme.set_type_variation(&"PrimaryButton", &"Button")
    theme.set_type_variation(&"DangerButton", &"Button")
    theme.set_color(&"font_color", &"Button", tokens.text)
    theme.set_color(&"font_color", &"PrimaryButton", tokens.text)
    theme.set_color(&"font_color", &"DangerButton", tokens.text)
    theme.set_constant(&"separation", &"VBoxContainer", tokens.spacing)
    theme.set_stylebox(&"normal", &"Button", _style(tokens.surface, tokens.corner_radius))
    theme.set_stylebox(&"normal", &"PrimaryButton", _style(tokens.primary, tokens.corner_radius))
    theme.set_stylebox(&"normal", &"DangerButton", _style(tokens.danger, tokens.corner_radius))
    return theme


static func _style(color: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = 16.0
    style.content_margin_right = 16.0
    style.content_margin_top = 10.0
    style.content_margin_bottom = 10.0
    return style
