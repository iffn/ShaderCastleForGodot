@tool
extends MeshInstance3D

@export_range(3, 32) var radial_segments: int = 8:
	set(value):
		radial_segments = value
		request_rebuild()

@export var base_radius: float = 0.1:
	set(value):
		base_radius = value
		request_rebuild()


# ==============================================================================
# Godot Built-ins
# ==============================================================================

func _ready() -> void:
	request_rebuild()


# ==============================================================================
# Public Functions
# ==============================================================================

func request_rebuild() -> void:
	if not is_inside_tree():
		return
	call_deferred("_rebuild_tree_mesh")


# ==============================================================================
# Private Functions
# ==============================================================================

func _on_branch_changed() -> void:
	request_rebuild()


func _collect_child_chain(start_node: BranchNode) -> Array[BranchNode]:
	var chain: Array[BranchNode] = [start_node]
	var current: Node = start_node

	while true:
		var next_branch: BranchNode = null
		for child in current.get_children():
			if child is BranchNode and child.is_inside_tree() and not child.is_queued_for_deletion():
				next_branch = child
				break
		if is_instance_valid(next_branch):
			chain.append(next_branch)
			current = next_branch
		else:
			break

	return chain


func _rebuild_tree_mesh() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return

	# Gather direct BranchNode children (Child 1 = Branch, Child 2 = Root)
	var direct_children: Array[BranchNode] = []
	for child in get_children():
		if child is BranchNode and child.is_inside_tree() and not child.is_queued_for_deletion():
			direct_children.append(child)

	if direct_children.is_empty():
		mesh = null
		return

	var positions: Array[Vector3] = []
	var radii: Array[float] = []

	# 1. Process Root Chain (Second child, if present)
	if direct_children.size() > 1:
		var root_nodes: Array[BranchNode] = _collect_child_chain(direct_children[1])
		var root_positions: Array[Vector3] = []
		var root_radii: Array[float] = []
		var current_radius: float = base_radius

		for node in root_nodes:
			root_positions.append(to_local(node.global_position))
			current_radius *= node._get_radius_multiplier()
			root_radii.append(current_radius)

		# Reverse arrays so sequence goes from tip (Root B) down to base (Root A)
		root_positions.reverse()
		root_radii.reverse()

		positions.append_array(root_positions)
		radii.append_array(root_radii)

	# 2. Process Tree Root Node (Origin)
	positions.append(Vector3.ZERO)
	radii.append(base_radius)

	# 3. Process Branch Chain (First child, if present)
	if direct_children.size() > 0:
		var branch_nodes: Array[BranchNode] = _collect_child_chain(direct_children[0])
		var current_radius: float = base_radius

		for node in branch_nodes:
			positions.append(to_local(node.global_position))
			current_radius *= node._get_radius_multiplier()
			radii.append(current_radius)

	_generate_chain_mesh(positions, radii)


func _generate_chain_mesh(positions: Array[Vector3], radii: Array[float]) -> void:
	var node_count: int = positions.size()
	if node_count < 2:
		mesh = null
		return

	# 1. Calculate segment direction vectors
	var segment_dirs: Array[Vector3] = []
	for i in range(node_count - 1):
		var dir: Vector3 = (positions[i + 1] - positions[i]).normalized()
		if dir.length_squared() < 0.001:
			dir = Vector3.UP
		segment_dirs.append(dir)

	# 2. Calculate forward alignment direction at each node (bisector framing)
	var forward_dirs: Array[Vector3] = []
	for i in range(node_count):
		if i == 0:
			forward_dirs.append(segment_dirs[0])
		elif i == node_count - 1:
			forward_dirs.append(segment_dirs[node_count - 2])
		else:
			var bisector: Vector3 = (segment_dirs[i - 1] + segment_dirs[i]).normalized()
			if bisector.length_squared() < 0.001:
				bisector = segment_dirs[i - 1]
			forward_dirs.append(bisector)

	# 3. Generate cross-sectional rings along the chain
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var prev_right: Vector3 = Vector3.ZERO

	for k in range(node_count):
		var fwd: Vector3 = forward_dirs[k]
		var right: Vector3

		if k == 0 or prev_right.length_squared() < 0.001:
			right = Vector3.UP.cross(fwd)
			if right.length_squared() < 0.001:
				right = Vector3.RIGHT.cross(fwd)
			right = right.normalized()
		else:
			right = (prev_right - fwd * prev_right.dot(fwd)).normalized()
			if right.length_squared() < 0.001:
				right = Vector3.UP.cross(fwd).normalized()

		prev_right = right
		var up: Vector3 = fwd.cross(right).normalized()
		var node_pos: Vector3 = positions[k]
		var radius: float = radii[k]

		# Add vertices for ring k
		for i in range(radial_segments):
			var angle: float = (float(i) / radial_segments) * TAU
			var normal: Vector3 = (right * cos(angle) + up * sin(angle)).normalized()
			var vertex_offset: Vector3 = normal * radius

			st.set_normal(normal)
			st.set_uv(Vector2(float(i) / radial_segments, float(k) / float(node_count - 1)))
			st.add_vertex(node_pos + vertex_offset)

	# 4. Bridge adjacent rings with quads
	for k in range(node_count - 1):
		var ring_a_start: int = k * radial_segments
		var ring_b_start: int = (k + 1) * radial_segments

		for i in range(radial_segments):
			var next_i: int = (i + 1) % radial_segments

			var b_curr: int = ring_a_start + i
			var b_next: int = ring_a_start + next_i
			var t_curr: int = ring_b_start + i
			var t_next: int = ring_b_start + next_i

			# Quad Triangle 1
			st.add_index(b_curr)
			st.add_index(t_curr)
			st.add_index(t_next)

			# Quad Triangle 2
			st.add_index(b_curr)
			st.add_index(t_next)
			st.add_index(b_next)

	mesh = st.commit()
