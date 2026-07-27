extends RefCounted


func run(_tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var tokens: TemplateThemeTokens = load("res://recipes/ui/theme-tokens/theme_tokens.tres")
    var theme := TemplateThemeFactory.build(tokens)
    if theme.get_type_variation_base(&"PrimaryButton") != &"Button":
        failures.append("PrimaryButton variation does not inherit Button")
    if theme.get_color(&"font_color", &"DangerButton") != tokens.text:
        failures.append("semantic danger button did not receive text token")
    if theme.get_constant(&"separation", &"VBoxContainer") != tokens.spacing:
        failures.append("layout spacing token was not installed")
    return failures
