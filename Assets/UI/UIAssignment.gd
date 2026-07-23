@tool
extends Node

@export var title : String
@export var description : String
@export var material : Material

@export var title_label : Label
@export var description_label : Label
@export var mesh : MeshInstance3D

@export var click_to_apply : bool:
	set(value):
		if value:
			apply_data()

@export var click_to_get_material : bool:
	set(value):
		if value:
			material = mesh.get_surface_override_material(0)

func apply_data() -> void:
	title_label.text = title
	description_label.text = description
	mesh.set_surface_override_material(0, material)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
