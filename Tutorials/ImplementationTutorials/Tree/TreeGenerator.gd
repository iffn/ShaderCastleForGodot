@tool
extends MeshInstance3D

@export_range(4, 32) var radial_segments: int = 8:
	set(value):
		radial_segments = value if value % 2 == 0 else value + 1
		request_rebuild()

@export var base_radius: float = 0.1:
	set(value):
		base_radius = value
		request_rebuild()

@export_range(0.0, 2.0, 0.05) var crotch_offset_factor: float = 0.5:
	set(value):
		crotch_offset_factor = value
		request_rebuild()

var _vertex_count: int = 0


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


func _get_valid_branch_children(node: Node, max_count: int = 2) -> Array[BranchNode]:
	var valid_children: Array[BranchNode] = []
	for child in node.get_children():
		if child is BranchNode and child.is_inside_tree() and not child.is_queued_for_deletion():
			valid_children.append(child)
			if valid_children.size() == max_count:
				break
	return valid_children

func _rebuild_tree_mesh() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return

	# Query up to 3 children: 1 Trunk (Child 0) + 2 Roots (Child 1 & Child 2)
	var direct_children: Array[BranchNode] = _get_valid_branch_children(self, 3)
	if direct_children.is_empty():
		mesh = null
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_vertex_count = 0

	var trunk_node: BranchNode = direct_children[0]
	var start_dir: Vector3 = (to_local(trunk_node.global_position) - Vector3.ZERO).normalized()
	if start_dir.length_squared() < 0.001:
		start_dir = Vector3.UP

	var initial_right: Vector3

	if direct_children.size() >= 3:
		# Root Y-split orientation setup
		var root_a: BranchNode = direct_children[1]
		var root_b: BranchNode = direct_children[2]

		var dir_a: Vector3 = (to_local(root_a.global_position) - Vector3.ZERO).normalized()
		if dir_a.length_squared() < 0.001:
			dir_a = -start_dir
		var dir_b: Vector3 = (to_local(root_b.global_position) - Vector3.ZERO).normalized()
		if dir_b.length_squared() < 0.001:
			dir_b = -start_dir

		var split_normal: Vector3 = dir_a.cross(dir_b)
		if split_normal.length_squared() > 0.001:
			initial_right = split_normal.normalized()
		else:
			initial_right = Vector3.UP.cross(start_dir)
			if initial_right.length_squared() < 0.001:
				initial_right = Vector3.RIGHT.cross(start_dir)
			initial_right = initial_right.normalized()

		# Single shared origin ring at Vector3.ZERO for both trunk and roots
		var base_ring: Dictionary = _generate_ring(st, Vector3.ZERO, start_dir, base_radius, initial_right, 0.0)

		# 1. Main Trunk Subtree (Child 0)
		_build_branch_subtree(st, trunk_node, base_ring.indices, Vector3.ZERO, start_dir, base_ring.right, base_ring.up, base_radius, 0.0, 1.0)

		# 2. Root Y-Split Subtrees (Child 1 & Child 2) sharing base_ring indices
		var rev_base_indices: Array[int] = []
		for i in range(radial_segments):
			rev_base_indices.append(base_ring.indices[(radial_segments - i) % radial_segments])

		var rev_right: Vector3 = base_ring.right
		var rev_up: Vector3 = -base_ring.up
		var rev_in_dir: Vector3 = -start_dir

		if dir_a.dot(rev_up) < dir_b.dot(rev_up):
			var temp_node: BranchNode = root_a
			root_a = root_b
			root_b = temp_node

			var temp_dir: Vector3 = dir_a
			dir_a = dir_b
			dir_b = temp_dir

		var split_dir: Vector3 = (dir_a + dir_b).normalized()
		if split_dir.length_squared() < 0.001:
			split_dir = rev_in_dir

		var crotch_pos: Vector3 = Vector3.ZERO + split_dir * (base_radius * crotch_offset_factor)
		var crotch_dist: float = 0.0 + (crotch_pos - Vector3.ZERO).length() * -1.0
		
		st.set_normal(split_dir)
		st.set_tangent(Plane(rev_right.x, rev_right.y, rev_right.z, 1.0))
		st.set_uv(Vector2(crotch_dist, base_radius))
		
		var crotch_idx: int = _vertex_count
		st.add_vertex(crotch_pos)
		_vertex_count += 1

		var half_count: int = radial_segments / 2

		var ring_a_indices: Array[int] = []
		for i in range(half_count + 1):
			ring_a_indices.append(rev_base_indices[i])
		ring_a_indices.append(crotch_idx)

		var ring_b_indices: Array[int] = []
		for i in range(half_count, radial_segments):
			ring_b_indices.append(rev_base_indices[i])
		ring_b_indices.append(rev_base_indices[0])
		ring_b_indices.append(crotch_idx)

		var right_a: Vector3 = _transport_frame(rev_in_dir, dir_a, rev_right)
		var up_a: Vector3 = _transport_frame(rev_in_dir, dir_a, rev_up)

		var right_b: Vector3 = _transport_frame(rev_in_dir, dir_b, -rev_right)
		var up_b: Vector3 = _transport_frame(rev_in_dir, dir_b, -rev_up)

		_build_branch_subtree(st, root_a, ring_a_indices, Vector3.ZERO, dir_a, right_a, up_a, base_radius * 0.75, 0.0, -1.0)
		_build_branch_subtree(st, root_b, ring_b_indices, Vector3.ZERO, dir_b, right_b, up_b, base_radius * 0.75, 0.0, -1.0)

	elif direct_children.size() == 2:
		# Single root + main trunk
		initial_right = Vector3.UP.cross(start_dir)
		if initial_right.length_squared() < 0.001:
			initial_right = Vector3.RIGHT.cross(start_dir)
		initial_right = initial_right.normalized()

		var base_ring: Dictionary = _generate_ring(st, Vector3.ZERO, start_dir, base_radius, initial_right, 0.0)
		_build_branch_subtree(st, trunk_node, base_ring.indices, Vector3.ZERO, start_dir, base_ring.right, base_ring.up, base_radius, 0.0, 1.0)

		var root_node: BranchNode = direct_children[1]
		var root_dir: Vector3 = (to_local(root_node.global_position) - Vector3.ZERO).normalized()
		if root_dir.length_squared() < 0.001:
			root_dir = -start_dir

		var rev_base_indices: Array[int] = []
		for i in range(radial_segments):
			rev_base_indices.append(base_ring.indices[(radial_segments - i) % radial_segments])

		var rev_right: Vector3 = base_ring.right
		var rev_up: Vector3 = -base_ring.up
		var rev_in_dir: Vector3 = -start_dir

		var root_right: Vector3 = _transport_frame(rev_in_dir, root_dir, rev_right)
		var root_up: Vector3 = _transport_frame(rev_in_dir, root_dir, rev_up)
		_build_branch_subtree(st, root_node, rev_base_indices, Vector3.ZERO, root_dir, root_right, root_up, base_radius, 0.0, -1.0)

	else:
		# Single trunk only, cap base
		initial_right = Vector3.UP.cross(start_dir)
		if initial_right.length_squared() < 0.001:
			initial_right = Vector3.RIGHT.cross(start_dir)
		initial_right = initial_right.normalized()

		var base_ring: Dictionary = _generate_ring(st, Vector3.ZERO, start_dir, base_radius, initial_right, 0.0)
		_cap_ring(st, base_ring.indices, Vector3.ZERO, -start_dir, 0.0)
		_build_branch_subtree(st, trunk_node, base_ring.indices, Vector3.ZERO, start_dir, base_ring.right, base_ring.up, base_radius, 0.0, 1.0)

	mesh = st.commit()


func _build_branch_subtree(st: SurfaceTool, current_node: BranchNode, parent_indices: Array[int], parent_pos: Vector3, in_dir: Vector3, parent_right: Vector3, parent_up: Vector3, parent_radius: float, current_distance: float, distance_sign: float) -> void:
	var node_pos: Vector3 = to_local(current_node.global_position)
	var current_radius: float = parent_radius * current_node._get_radius_multiplier()
	var children: Array[BranchNode] = _get_valid_branch_children(current_node, 2)
	
	var segment_length: float = (node_pos - parent_pos).length()
	var next_distance: float = current_distance + (segment_length * distance_sign)

	if children.size() <= 1:
		# --- LINEAR SEGMENT ---
		var out_dir: Vector3 = in_dir
		if children.size() == 1:
			out_dir = (to_local(children[0].global_position) - node_pos).normalized()

		var node_dir: Vector3 = (in_dir + out_dir).normalized()
		if node_dir.length_squared() < 0.001:
			node_dir = in_dir

		var ring_right: Vector3 = _transport_frame(in_dir, node_dir, parent_right)
		var ring_up: Vector3 = _transport_frame(in_dir, node_dir, parent_up)
		var ring: Dictionary = _generate_ring_with_basis(st, node_pos, node_dir, current_radius, ring_right, ring_up, next_distance)

		if parent_indices.size() == radial_segments:
			_bridge_rings_equal(st, parent_indices, ring.indices)
		else:
			_bridge_half_to_full_ring(st, parent_indices, ring.indices)

		if children.size() == 1:
			var next_right: Vector3 = _transport_frame(node_dir, out_dir, ring.right)
			var next_up: Vector3 = _transport_frame(node_dir, out_dir, ring.up)
			_build_branch_subtree(st, children[0], ring.indices, node_pos, out_dir, next_right, next_up, current_radius, next_distance, distance_sign)
		else:
			_cap_ring(st, ring.indices, node_pos, out_dir, next_distance)

	else:
		# --- Y INTERSECTION TOPOLOGY ---
		var child_a: BranchNode = children[0]
		var child_b: BranchNode = children[1]

		var dir_a: Vector3 = (to_local(child_a.global_position) - node_pos).normalized()
		var dir_b: Vector3 = (to_local(child_b.global_position) - node_pos).normalized()

		var split_dir: Vector3 = (dir_a + dir_b).normalized()
		var junction_dir: Vector3 = (in_dir + split_dir).normalized()
		if junction_dir.length_squared() < 0.001:
			junction_dir = in_dir

		var transported_right: Vector3 = _transport_frame(in_dir, junction_dir, parent_right)
		var transported_up: Vector3 = _transport_frame(in_dir, junction_dir, parent_up)
		var split_normal: Vector3 = dir_a.cross(dir_b)
		var junction_right: Vector3

		if split_normal.length_squared() > 0.001:
			junction_right = split_normal.normalized()
			if junction_right.dot(transported_right) < 0.0:
				junction_right = -junction_right
		else:
			junction_right = transported_right

		var junction_ring: Dictionary = _generate_ring_with_basis(st, node_pos, junction_dir, current_radius, junction_right, transported_up, next_distance)

		# Spatial alignment check
		if dir_a.dot(junction_ring.up) < dir_b.dot(junction_ring.up):
			var temp_node: BranchNode = child_a
			child_a = child_b
			child_b = temp_node

			var temp_dir: Vector3 = dir_a
			dir_a = dir_b
			dir_b = temp_dir

		if parent_indices.size() == radial_segments:
			_bridge_rings_equal(st, parent_indices, junction_ring.indices)
		else:
			_bridge_half_to_full_ring(st, parent_indices, junction_ring.indices)

		var crotch_pos: Vector3 = node_pos + split_dir * (current_radius * crotch_offset_factor)
		var crotch_dist: float = next_distance + (crotch_pos - node_pos).length() * distance_sign
		
		# For the crotch, tangency to junction_right prevents breaking normal calculation
		st.set_normal(split_dir)
		st.set_tangent(Plane(junction_right.x, junction_right.y, junction_right.z, 1.0))
		st.set_uv(Vector2(crotch_dist, current_radius))
		
		var crotch_idx: int = _vertex_count
		st.add_vertex(crotch_pos)
		_vertex_count += 1

		var half_count: int = radial_segments / 2

		var ring_a_indices: Array[int] = []
		for i in range(half_count + 1):
			ring_a_indices.append(junction_ring.indices[i])
		ring_a_indices.append(crotch_idx)

		var ring_b_indices: Array[int] = []
		for i in range(half_count, radial_segments):
			ring_b_indices.append(junction_ring.indices[i])
		ring_b_indices.append(junction_ring.indices[0])
		ring_b_indices.append(crotch_idx)

		var right_a: Vector3 = _transport_frame(junction_dir, dir_a, junction_ring.right)
		var up_a: Vector3 = _transport_frame(junction_dir, dir_a, junction_ring.up)

		var right_b: Vector3 = _transport_frame(junction_dir, dir_b, -junction_ring.right)
		var up_b: Vector3 = _transport_frame(junction_dir, dir_b, -junction_ring.up)

		_build_branch_subtree(st, child_a, ring_a_indices, node_pos, dir_a, right_a, up_a, current_radius * 0.75, next_distance, distance_sign)
		_build_branch_subtree(st, child_b, ring_b_indices, node_pos, dir_b, right_b, up_b, current_radius * 0.75, next_distance, distance_sign)


func _generate_ring(st: SurfaceTool, center: Vector3, dir: Vector3, radius: float, ref_right: Vector3, distance: float) -> Dictionary:
	var norm_dir: Vector3 = dir.normalized()
	var right: Vector3 = (ref_right - norm_dir * ref_right.dot(norm_dir)).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.UP.cross(norm_dir)
		if right.length_squared() < 0.001:
			right = Vector3.RIGHT.cross(norm_dir)
		right = right.normalized()

	var up: Vector3 = norm_dir.cross(right).normalized()
	return _generate_ring_with_basis(st, center, norm_dir, radius, right, up, distance)


func _generate_ring_with_basis(st: SurfaceTool, center: Vector3, dir: Vector3, radius: float, ref_right: Vector3, ref_up: Vector3, distance: float) -> Dictionary:
	var ring_indices: Array[int] = []
	var norm_dir: Vector3 = dir.normalized()

	var right: Vector3 = (ref_right - norm_dir * ref_right.dot(norm_dir)).normalized()
	var up: Vector3 = (ref_up - norm_dir * ref_up.dot(norm_dir)).normalized()
	up = (up - right * up.dot(right)).normalized()

	var start_vertex_idx: int = _vertex_count
	var tangent_plane := Plane(norm_dir.x, norm_dir.y, norm_dir.z, 1.0)

	for i in range(radial_segments):
		var angle: float = (float(i) / float(radial_segments)) * TAU
		var normal: Vector3 = (right * cos(angle) + up * sin(angle)).normalized()
		var vertex_pos: Vector3 = center + normal * radius

		st.set_normal(normal)
		st.set_tangent(tangent_plane)
		st.set_uv(Vector2(distance, radius))
		st.add_vertex(vertex_pos)

		ring_indices.append(start_vertex_idx + i)

	_vertex_count += radial_segments
	return {
		"indices": ring_indices,
		"right": right,
		"up": up
	}


func _cap_ring(st: SurfaceTool, ring_indices: Array[int], center: Vector3, normal: Vector3, distance: float) -> void:
	var cap_tangent: Vector3 = Vector3.UP.cross(normal)
	if cap_tangent.length_squared() < 0.001:
		cap_tangent = Vector3.RIGHT.cross(normal)
	cap_tangent = cap_tangent.normalized()
	
	st.set_normal(normal)
	st.set_tangent(Plane(cap_tangent.x, cap_tangent.y, cap_tangent.z, 1.0))
	st.set_uv(Vector2(distance, 0.0))
	
	var center_idx: int = _vertex_count
	st.add_vertex(center)
	_vertex_count += 1

	var count: int = ring_indices.size()
	for i in range(count):
		var next_i: int = (i + 1) % count
		st.add_index(center_idx)
		st.add_index(ring_indices[i])
		st.add_index(ring_indices[next_i])


func _transport_frame(from_dir: Vector3, to_dir: Vector3, ref_vec: Vector3) -> Vector3:
	var f_norm := from_dir.normalized()
	var t_norm := to_dir.normalized()

	if f_norm.is_equal_approx(t_norm) or f_norm.is_equal_approx(-t_norm):
		var proj := ref_vec - t_norm * ref_vec.dot(t_norm)
		return proj.normalized() if proj.length_squared() > 0.001 else ref_vec

	var q := Quaternion(f_norm, t_norm)
	var transported := q * ref_vec
	var proj := transported - t_norm * transported.dot(t_norm)
	return proj.normalized() if proj.length_squared() > 0.001 else transported.normalized()


func _bridge_rings_equal(st: SurfaceTool, ring_a: Array[int], ring_b: Array[int]) -> void:
	var count: int = ring_a.size()
	for i in range(count):
		var next_i: int = (i + 1) % count

		st.add_index(ring_a[i])
		st.add_index(ring_b[i])
		st.add_index(ring_b[next_i])

		st.add_index(ring_a[i])
		st.add_index(ring_b[next_i])
		st.add_index(ring_a[next_i])


func _bridge_half_to_full_ring(st: SurfaceTool, half_ring: Array[int], full_ring: Array[int]) -> void:
	var n: int = full_ring.size()
	var h: int = n / 2
	var crotch_idx: int = half_ring[h + 1]

	# 1. Front half quads
	for i in range(h):
		st.add_index(half_ring[i])
		st.add_index(full_ring[i])
		st.add_index(full_ring[i + 1])

		st.add_index(half_ring[i])
		st.add_index(full_ring[i + 1])
		st.add_index(half_ring[i + 1])

	# 2. Back half fan from crotch
	for j in range(h, n):
		var next_j: int = (j + 1) % n
		st.add_index(crotch_idx)
		st.add_index(full_ring[j])
		st.add_index(full_ring[next_j])

	# 3. Corner sealing triangles
	st.add_index(crotch_idx)
	st.add_index(full_ring[0])
	st.add_index(half_ring[0])

	st.add_index(crotch_idx)
	st.add_index(half_ring[h])
	st.add_index(full_ring[h])
