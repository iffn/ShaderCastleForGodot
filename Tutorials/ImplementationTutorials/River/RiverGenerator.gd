@tool
class_name RiverMeshGenerator
extends MeshInstance3D

@export var update_mesh: bool = false:
	set(val):
		generate_river()

@export_range(1, 50, 1) var subdivisions_per_segment: int = 10
@export_range(1, 20, 1) var subdivisions_width: int = 4
@export var speed_curve: Curve
@export var texture_tiling_x: float = 1.0

func _ready() -> void:
	generate_river()

func request_rebuild() -> void:
	if is_inside_tree():
		call_deferred("generate_river")

func _on_waypoint_changed() -> void:
	if is_inside_tree():
		call_deferred("generate_river")

func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * (t * t) +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * (t * t * t)
	)

func generate_river() -> void:
	var waypoints: Array[Node3D] = []
	for child in get_children():
		if child is Node3D and child.is_inside_tree():
			waypoints.append(child)
	
	if waypoints.size() < 2:
		return
		
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var sampled_points: Array[Dictionary] = []
	
	for i in range(waypoints.size() - 1):
		var p0 = waypoints[max(0, i - 1)].global_position
		var p1 = waypoints[i].global_position
		var p2 = waypoints[i + 1].global_position
		var p3 = waypoints[min(waypoints.size() - 1, i + 2)].global_position
		
		var w1 = waypoints[i].scale.x
		var w2 = waypoints[i + 1].scale.x
		
		for step in range(subdivisions_per_segment):
			var t = float(step) / float(subdivisions_per_segment)
			var pos = _catmull_rom(p0, p1, p2, p3, t)
			var width = lerp(w1, w2, t)
			
			sampled_points.append({
				"position": pos,
				"width": width
			})
			
	# Append the final waypoint anchor point
	var final_wp = waypoints[waypoints.size() - 1]
	sampled_points.append({
		"position": final_wp.global_position,
		"width": final_wp.scale.x
	})
	
	# Calculate UV.y based on distance modulated by inclination speed curve
	var distances: PackedFloat32Array = [0.0]
	var current_uv_y: float = 0.0
	
	for i in range(1, sampled_points.size()):
		var p_prev = sampled_points[i - 1]["position"]
		var p_curr = sampled_points[i]["position"]
		var segment_dist = p_curr.distance_to(p_prev)
		
		var tangent = (p_curr - p_prev).normalized()
		var inclination = abs(tangent.y) # 0.0 is flat, 1.0 is vertical
		
		var speed_mult = 1.0
		if speed_curve:
			speed_mult = speed_curve.sample(inclination)
			
		current_uv_y += segment_dist * speed_mult
		distances.append(current_uv_y)
		
	# Extract uniform scale factor from global transform to treat the whole generator as a miniature
	var global_scale_factor = global_transform.basis.get_scale().x
	var inv_transform = global_transform.affine_inverse()
	var strip_data = []
	
	for i in range(sampled_points.size()):
		var pt = sampled_points[i]
		var pos = pt["position"]
		# Scale width relative to the MeshInstance3D's global scale for miniature support
		var width = pt["width"] * global_scale_factor
		var uv_y = distances[i]
		
		var tangent: Vector3
		if i == 0:
			tangent = (sampled_points[1]["position"] - pos).normalized()
		elif i == sampled_points.size() - 1:
			tangent = (pos - sampled_points[i-1]["position"]).normalized()
		else:
			tangent = (sampled_points[i+1]["position"] - sampled_points[i-1]["position"]).normalized()
			
		var side = tangent.cross(Vector3.UP).normalized()
		if side.is_zero_approx():
			side = Vector3.RIGHT
			
		var half_width = width * 0.5
		var row = []
		
		for j in range(subdivisions_width + 1):
			var t_w = float(j) / float(subdivisions_width)
			var offset = lerp(-half_width, half_width, t_w) / global_scale_factor
			var v_pos = inv_transform * (pos + side * (offset * global_scale_factor))
			var uv_x = t_w * pt["width"] * texture_tiling_x
			
			row.append({
				"pos": v_pos,
				"uv": Vector2(uv_x, uv_y)
			})
			
		strip_data.append(row)
		
	for i in range(strip_data.size() - 1):
		var curr_row = strip_data[i]
		var next_row = strip_data[i+1]
		
		for j in range(subdivisions_width):
			var v00 = curr_row[j]
			var v10 = curr_row[j+1]
			var v01 = next_row[j]
			var v11 = next_row[j+1]
			
			# Triangle 1
			st.set_uv(v00.uv)
			st.add_vertex(v00.pos)
			st.set_uv(v01.uv)
			st.add_vertex(v01.pos)
			st.set_uv(v10.uv)
			st.add_vertex(v10.pos)
			
			# Triangle 2
			st.set_uv(v10.uv)
			st.add_vertex(v10.pos)
			st.set_uv(v01.uv)
			st.add_vertex(v01.pos)
			st.set_uv(v11.uv)
			st.add_vertex(v11.pos)
		
	st.generate_normals()
	mesh = st.commit()
