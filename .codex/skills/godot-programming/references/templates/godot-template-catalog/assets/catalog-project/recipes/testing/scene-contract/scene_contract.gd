class_name TemplateSceneContract
extends RefCounted


func validate(
    root: Node,
    required_nodes: Array[NodePath],
    required_signals: Dictionary,
    required_resource_properties: Array[StringName],
    required_input_actions: Array[StringName]
) -> Array[String]:
    var errors: Array[String] = []
    if root == null:
        return ["root is null"]

    for path in required_nodes:
        if root.get_node_or_null(path) == null:
            errors.append("missing node: %s" % path)

    for path: Variant in required_signals:
        var node := root.get_node_or_null(NodePath(path))
        if node == null:
            errors.append("missing signal owner: %s" % path)
            continue
        var signal_names: Variant = required_signals[path]
        for signal_name: Variant in signal_names:
            if not node.has_signal(StringName(signal_name)):
                errors.append("missing signal %s on %s" % [signal_name, path])

    for property_name in required_resource_properties:
        if not root.get(property_name) is Resource:
            errors.append("property is not a Resource: %s" % property_name)

    for action in required_input_actions:
        if not InputMap.has_action(action):
            errors.append("missing input action: %s" % action)

    return errors
