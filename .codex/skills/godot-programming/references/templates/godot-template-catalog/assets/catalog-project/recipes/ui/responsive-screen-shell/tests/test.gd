extends RefCounted


func run(_tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var shell := TemplateResponsiveShell.new()
    shell.size = Vector2(375, 700)
    shell.refresh_mode()
    if not shell.is_narrow:
        failures.append("375px width was not classified as narrow")
    shell.size = Vector2(799, 450)
    shell.refresh_mode()
    if shell.is_narrow:
        failures.append("799px width was not classified as wide")
    shell.free()
    return failures
