@tool
class_name RiverMeshGenerator
extends MeshInstance3D

@export var update_mesh: bool = false:
	set(val):
		generate_river()

func _ready() -> void:
	generate_river()

func request_rebuild() -> void:
	generate_river()

func _on_waypoint_changed() -> void:
	generate_river()

func generate_river() -> void:
	var waypoints: Array[Node3D] = []
	for child in get_children():
		if child is Node3D:
			waypoints.append(child)
	
	if waypoints.size() < 2:
		return
		
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var total_length: float = 0.0
	var distances: PackedFloat32Array = [0.0]
	
	for i in range(1, waypoints.size()):
		var dist = waypoints[i].global_position.distance_to(waypoints[i-1].global_position)
		total_length += dist
		distances.append(total_length)
		
	var inv_transform = global_transform.affine_inverse()
	var strip_data = []
	
	for i in range(waypoints.size()):
		var wp = waypoints[i]
		var pos = wp.global_position
		
		var tangent: Vector3
		if i == 0:
			tangent = (waypoints[1].global_position - pos).normalized()
		elif i == waypoints.size() - 1:
			tangent = (pos - waypoints[i-1].global_position).normalized()
		else:
			tangent = (waypoints[i+1].global_position - waypoints[i-1].global_position).normalized()
			
		var side = tangent.cross(Vector3.UP).normalized()
		if side.is_zero_approx():
			side = Vector3.RIGHT
			
		var river_size = wp.scale.x
		var half_width = river_size * 0.5
		
		var left_pos = inv_transform * (pos - side * half_width)
		var right_pos = inv_transform * (pos + side * half_width)
		
		strip_data.append({
			"left": left_pos,
			"right": right_pos,
			"uv_y": distances[i],
			"size": river_size
		})
		
	for i in range(strip_data.size() - 1):
		var curr = strip_data[i]
		var next = strip_data[i+1]
		
		# Triangle 1
		st.set_uv(Vector2(0.0, curr.uv_y))
		st.add_vertex(curr.left)
		st.set_uv(Vector2(0.0, next.uv_y))
		st.add_vertex(next.left)
		st.set_uv(Vector2(curr.size, curr.uv_y))
		st.add_vertex(curr.right)
		
		# Triangle 2
		st.set_uv(Vector2(curr.size, curr.uv_y))
		st.add_vertex(curr.right)
		st.set_uv(Vector2(0.0, next.uv_y))
		st.add_vertex(next.left)
		st.set_uv(Vector2(next.size, next.uv_y))
		st.add_vertex(next.right)
		
	st.generate_normals()
	mesh = st.commit()
