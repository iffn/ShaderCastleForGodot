@tool
extends Node

@export_category("Display settings")
@export var title : String = "Title"
@export_multiline var description : String = "Description"
@export var material : Material
@export var meshToDisplay : Mesh
@export var display_scale := 0.3
@export var euler_angles := Vector3(0, 0,  0)
@export var hovering := true

@export_category("Prefab settings")
@export var title_label : Label
@export var description_label : Label
@export var displayMesh : MeshInstance3D
@export var displayOrigin : Node3D

@export_category("Apply")
@export var click_to_apply : bool:
	set(value):
		if value:
			apply_data()

@export var click_to_get_material : bool:
	set(value):
		if value:
			material = displayMesh.get_surface_override_material(0)

func apply_data() -> void:
	title_label.text = title
	description_label.text = description
	if meshToDisplay:
		displayMesh.mesh = meshToDisplay
	displayMesh.set_surface_override_material(0, material)
	displayMesh.scale = display_scale * Vector3.ONE
	displayMesh.rotation = euler_angles * deg_to_rad(1)
	displayOrigin.position.y = 1.3 if hovering else 1.001

func _ready() -> void:
	apply_data()
