extends RefCounted


func run(_tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var scene: PackedScene = load("res://recipes/testing/scene-contract/demo.tscn")
    var fixture: TemplateSceneContractFixture = scene.instantiate()
    var contract := TemplateSceneContract.new()
    var valid := contract.validate(
        fixture,
        [NodePath("RequiredChild")],
        {NodePath("."): [&"activated"]},
        [&"config"],
        []
    )
    if not valid.is_empty():
        failures.append("valid fixture failed contract: %s" % valid)
    var invalid := contract.validate(
        fixture,
        [NodePath("MissingChild")],
        {},
        [],
        []
    )
    if invalid.is_empty():
        failures.append("missing required node was not reported")
    fixture.free()
    return failures
