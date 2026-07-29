class_name UiArtDirection
extends RefCounted

const BUTTON_NEUTRAL: Texture2D = preload(
	"res://assets/ui/frames/kenney_ui_sci_fi/button_frame_neutral.png"
)
const BUTTON_PRIMARY: Texture2D = preload(
	"res://assets/ui/frames/kenney_ui_sci_fi/button_frame_primary.png"
)
const PANEL_FRAME: Texture2D = preload(
	"res://assets/ui/frames/kenney_ui_sci_fi/panel_frame.png"
)


static func button_style(primary: bool, state: String = "normal") -> StyleBoxTexture:
	var style := _texture_box(BUTTON_PRIMARY if primary else BUTTON_NEUTRAL, 22.0)
	var color := Color("#f2bd48") if primary else Color("#17242c")
	match state:
		"hover":
			color = Color("#ffd36b") if primary else Color("#25414b")
		"pressed":
			color = Color("#c88d2f") if primary else Color("#102f38")
		"focus":
			color = Color("#ffe199") if primary else Color("#315b66")
		"disabled":
			color = Color("#34383b")
	style.modulate_color = color
	return style


static func panel_style(alpha: float = 0.92) -> StyleBoxTexture:
	var style := _texture_box(PANEL_FRAME, 20.0)
	style.modulate_color = Color(0.045, 0.09, 0.115, alpha)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


static func _texture_box(texture: Texture2D, margin: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style
