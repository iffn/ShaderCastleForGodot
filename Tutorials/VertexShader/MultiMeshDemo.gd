@tool
extends Node

@export var linkedMultipMesh: MultiMeshInstance3D
@export var mesh: Mesh
@export var material: Material
@export var instance_count: int = 1000
@export var side_length: float = 2.0
@export var min_size = 1.0;
@export var max_size = 1.0;

@export var generate_mesh: bool = false:
	set(val):
		spread_meshes()

@export_group("Transform Options")
@export var mesh_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	spread_meshes()

func spread_meshes() -> void:
	if not mesh or not linkedMultipMesh:
		return
		
	# Apply material override to the MultiMeshInstance3D
	if material:
		linkedMultipMesh.material_override = material

	# Create the MultiMesh object once if it doesn't exist
	if not linkedMultipMesh.multimesh:
		linkedMultipMesh.multimesh = MultiMesh.new()
		linkedMultipMesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		linkedMultipMesh.multimesh.use_custom_data = true

	# Update base properties
	linkedMultipMesh.multimesh.mesh = mesh
	linkedMultipMesh.multimesh.instance_count = instance_count

	# Determine grid bounds
	var side_count: int = int(ceil(sqrt(instance_count)))
	var half_side_length = side_length * 0.5

	for i in range(instance_count):
		# Base grid position
		var x: float = randf_range(-half_side_length, half_side_length)
		var z: float = randf_range(-half_side_length, half_side_length)
		# 1. Randomize position within cell bounds
		# 2. Build Transform3D with scale and rotation
		var t := Transform3D.IDENTITY

		# Apply scale
		var scale := randf_range(min_size, max_size)
		t = t.scaled(mesh_scale * scale)

		# Apply Y-axis rotation
		t = t.rotated(Vector3.UP, randf() * TAU)

		# Set final position
		t.origin = Vector3(x, 0.0, z)

		linkedMultipMesh.multimesh.set_instance_transform(i, t)

		# Pass custom data: (random_seed, speed, offset, unused)
		var custom_data := Color(randf(), randf_range(1.0, 3.0), randf() * TAU, 0.0)
		linkedMultipMesh.multimesh.set_instance_custom_data(i, custom_data)
