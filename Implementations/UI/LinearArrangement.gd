@tool
extends Node3D

@export var offset : Vector3 = Vector3(1.0, 0.0, 0.0)
@export var arrange_around_the_center : bool

@export var click_to_apply : bool:
	set(value):
		if value:
			arrange()

func arrange() -> void:
	var children: Array[Node3D] = []
	for child in get_children():
		if child is Node3D and child.visible:
			children.append(child)

	var child_count: int = children.size()
	
	var base_offset = Vector3.ZERO
	if arrange_around_the_center:
		base_offset = -0.5 * (child_count - 1) * offset

	for i in range(child_count):
		var child : Node3D = children[i]

		child.position = i * offset + base_offset
