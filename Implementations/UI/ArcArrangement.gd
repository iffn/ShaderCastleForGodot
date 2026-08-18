@tool
extends Node3D

@export var radius : float
@export var angle_offset_deg : float
@export var arrange_clockwise : bool

@export var inverse_order : bool
@export var half_offset : bool
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
	var angle_offset_rad: float = deg_to_rad(angle_offset_deg)

	for i in range(child_count):
		var angle_rad: float
		var child: Node3D

		var inverse_arrangement: float = 1.0 if arrange_clockwise else -1.0

		if arrange_around_the_center:
			inverse_arrangement *= -1.0
			child = children[i]

			var total_angle_rad: float = inverse_arrangement * (child_count - 1) * angle_offset_rad
			angle_rad = -total_angle_rad * 0.5 + inverse_arrangement * i * angle_offset_rad
		else:
			var index: int = (child_count - 1 - i) if inverse_order else i
			child = children[index]

			var used_half_offset: float = 0.5 if half_offset else 0.0
			angle_rad = -inverse_arrangement * (i + used_half_offset) * angle_offset_rad

		# Godot rotation vector uses radians directly (Y-axis rotation)
		child.rotation = Vector3(0, -angle_rad, 0)

		# Local position calculation using radius
		child.position = Vector3(
			-sin(angle_rad) * radius,
			0.0,
			cos(angle_rad) * radius
		)
