class_name DamageData
extends RefCounted

var source_id: StringName
var attack_instance_id: StringName
var amount: int
var hit_position: Vector3
var impulse: Vector3
var tags: Array[StringName]


func _init(
	p_source_id: StringName,
	p_attack_instance_id: StringName,
	p_amount: int,
	p_hit_position: Vector3 = Vector3.ZERO,
	p_impulse: Vector3 = Vector3.ZERO,
	p_tags: Array[StringName] = []
) -> void:
	source_id = p_source_id
	attack_instance_id = p_attack_instance_id
	amount = maxi(0, p_amount)
	hit_position = p_hit_position
	impulse = p_impulse
	tags = p_tags.duplicate()
