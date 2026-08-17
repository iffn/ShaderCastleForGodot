@tool
extends MeshInstance3D

@export_range(3, 32) var radial_segments: int = 8:
	set(value):
		radial_segments = value
		_rebuild_tree_mesh()

@export var base_radius: float = 0.1:
	set(value):
		base_radius = value
		_rebuild_tree_mesh()


# ==============================================================================
# Godot Built-ins
# ==============================================================================

func _ready() -> void:
	child_entered_tree.connect(_on_child_tree_changed)
	child_exiting_tree.connect(_on_child_tree_changed)
	_connect_branch_signals()
	_rebuild_tree_mesh()


# ==============================================================================
# Public Functions
# ==============================================================================

# Public API for external node interactions can be added here as needed.


# ==============================================================================
# Private Functions
# ==============================================================================

func _on_child_tree_changed(_node: Node) -> void:
	_connect_branch_signals()
	_rebuild_tree_mesh()


func _connect_branch_signals() -> void:
	for child in get_children():
		if child is BranchNode:
			if not child.branch_changed.is_connected(_rebuild_tree_mesh):
				child.branch_changed.connect(_rebuild_tree_mesh)


func _get_first_branch_child() -> BranchNode:
	for child in get_children():
		if child is BranchNode:
			return child
	return null


func _rebuild_tree_mesh() -> void:
	var branch: BranchNode = _get_first_branch_child()
	if not is_instance_valid(branch):
		mesh = null
		return

	var target_pos: Vector3 = branch.position
	var length: float = target_pos.length()
	if length < 0.001:
		mesh = null
		return

	var radius_multiplier: float = branch._get_radius_multiplier()
	_generate_tube(target_pos, radius_multiplier)


func _generate_tube(target_pos: Vector3, child_radius_multiplier: float) -> void:
	var dir: Vector3 = target_pos.normalized()
	var right: Vector3 = Vector3.UP.cross(dir)
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT.cross(dir)
	right = right.normalized()
	var forward: Vector3 = dir.cross(right).normalized()

	var top_radius: float = base_radius * child_radius_multiplier

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Generate vertex rings at origin (base_radius) and target_pos (top_radius)
	for i in range(radial_segments):
		var angle: float = (float(i) / radial_segments) * TAU
		var normal: Vector3 = (right * cos(angle) + forward * sin(angle)).normalized()
		var bottom_offset: Vector3 = normal * base_radius
		var top_offset: Vector3 = normal * top_radius

		# Bottom ring vertex (Origin)
		st.set_normal(normal)
		st.set_uv(Vector2(float(i) / radial_segments, 0.0))
		st.add_vertex(bottom_offset)

		# Top ring vertex (Child Position)
		st.set_normal(normal)
		st.set_uv(Vector2(float(i) / radial_segments, 1.0))
		st.add_vertex(target_pos + top_offset)

	# Bridge rings with quad triangles
	for i in range(radial_segments):
		var next_i: int = (i + 1) % radial_segments

		var b_curr: int = i * 2
		var t_curr: int = i * 2 + 1
		var b_next: int = next_i * 2
		var t_next: int = next_i * 2 + 1

		# Quad Triangle 1
		st.add_index(b_curr)
		st.add_index(t_curr)
		st.add_index(t_next)

		# Quad Triangle 2
		st.add_index(b_curr)
		st.add_index(t_next)
		st.add_index(b_next)

	mesh = st.commit()
