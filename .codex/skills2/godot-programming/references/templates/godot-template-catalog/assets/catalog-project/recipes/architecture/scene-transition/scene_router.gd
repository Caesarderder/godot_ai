class_name TemplateSceneRouter
extends Node

signal transitioned(scene: Node)
signal transition_failed(reason: String)

@export var host_path: NodePath = ^"Host"

var current_scene: Node


func transition_to(scene: PackedScene) -> bool:
    var host := get_node_or_null(host_path)
    if host == null:
        transition_failed.emit("missing_host")
        return false
    if scene == null:
        transition_failed.emit("missing_scene")
        return false

    var next_scene := scene.instantiate()
    if current_scene != null and is_instance_valid(current_scene):
        current_scene.queue_free()
    host.add_child(next_scene)
    current_scene = next_scene
    transitioned.emit(current_scene)
    return true
