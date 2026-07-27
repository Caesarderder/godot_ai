extends RefCounted


func run(_tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var scene: PackedScene = load("res://recipes/ui/component-gallery-core/demo.tscn")
    var gallery: TemplateComponentGallery = scene.instantiate()
    var normal := gallery.get_node("Scroll/Layout/Buttons/Normal") as Button
    var disabled := gallery.get_node("Scroll/Layout/Buttons/Disabled") as Button
    var progress := gallery.get_node("Scroll/Layout/Progress") as ProgressBar
    if normal.focus_mode != Control.FOCUS_ALL:
        failures.append("normal button is not keyboard/controller focusable")
    if not disabled.disabled:
        failures.append("disabled state is missing")
    if progress.value <= 0.0 or progress.value >= 100.0:
        failures.append("progress state is not visibly representative")
    gallery.free()
    return failures
