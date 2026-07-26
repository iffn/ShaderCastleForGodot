@tool
extends Node

@export_category("Display settings")
@export var title : String = "Title"
@export var description : String = "Description"
@export var material : Material
@export var meshToDisplay : Mesh

@export_category("Prefab settings")
@export var title_label : Label
@export var description_label : Label
@export var displayMesh : MeshInstance3D

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

func _ready() -> void:
	apply_data()
