extends RefCounted


func run(tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var scene: PackedScene = load("res://recipes/gameplay/damage-pipeline/demo.tscn")
    var demo: Node2D = scene.instantiate()
    tree.root.add_child(demo)
    var health := demo.get_node("Health") as TemplateHealthComponent
    var hitbox := demo.get_node("Hitbox") as TemplateHitbox
    await tree.physics_frame
    await tree.physics_frame
    if hitbox.damage == null:
        failures.append("hitbox damage data was not configured")
    if health.current != 6:
        failures.append("Area2D overlap did not flow from hitbox through hurtbox to health")
    demo.queue_free()
    return failures
