@tool
extends Node

@export_category("User setting")
@export var resolution := Vector2i(512, 512)
@export var compute_material : ShaderMaterial
@export var output_material : ShaderMaterial
@export var output_variable_name : String

@export_category("Prefab settings")
@export var compute_viewport : SubViewport
@export var compute_rect : ColorRect
@export var buffer_viewport : SubViewport
@export var buffer_rect : ColorRect

@export_category("Apply")
@export var click_to_apply : bool:
	set(value):
		if value and is_inside_tree():
			apply_data()

func _ready() -> void:
	# apply_data()
	pass

const buffer_path := "res://ShaderCastleForGodot/Tutorials/ComputeLike/Buffer.gdshader"

func apply_data() -> void:
	if not is_inside_tree():
		return
	if not compute_viewport or not buffer_viewport or not compute_rect or not buffer_rect or not compute_material:
		push_warning("Missing node or material assignments.")
		return

	# Configure Viewports
	compute_viewport.size = resolution
	compute_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	compute_viewport.disable_3d = true
	compute_viewport.use_hdr_2d = true

	buffer_viewport.size = resolution
	buffer_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	buffer_viewport.disable_3d = true
	buffer_viewport.use_hdr_2d = true

	# Configure Rects
	compute_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	compute_rect.size = Vector2(resolution)

	buffer_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	buffer_rect.size = Vector2(resolution)

	# Assign or reuse compute material
	var compute_mat := compute_rect.material as ShaderMaterial
	if compute_mat == null:
		compute_mat = compute_material.duplicate() as ShaderMaterial
		compute_mat.resource_local_to_scene = true
		compute_rect.material = compute_mat

	# Assign or reuse buffer material
	var buffer_mat := buffer_rect.material as ShaderMaterial
	if buffer_mat == null:
		var buffer_shader := load(buffer_path) as Shader
		buffer_mat = ShaderMaterial.new()
		buffer_mat.shader = buffer_shader
		buffer_mat.resource_local_to_scene = true
		buffer_rect.material = buffer_mat
	
	buffer_mat.set_shader_parameter("compute_map", compute_viewport.get_texture())
	compute_mat.set_shader_parameter("buffer_map", buffer_viewport.get_texture())
	
	output_material.resource_local_to_scene = true
	output_material.set_shader_parameter(output_variable_name, compute_viewport.get_texture())
