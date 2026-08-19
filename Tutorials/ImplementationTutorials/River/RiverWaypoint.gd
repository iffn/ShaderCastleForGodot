@tool
class_name RiverWaypoint
extends Node3D

signal waypoint_changed

var _last_transform: Transform3D

func _ready() -> void:
	_last_transform = transform
	set_notify_transform(true)

func _enter_tree() -> void:
	_register_to_generator()

func _exit_tree() -> void:
	_unregister_from_generator()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if not transform.is_equal_approx(_last_transform):
			_last_transform = transform
			waypoint_changed.emit()

func _find_generator() -> Node:
	var current: Node = get_parent()
	while is_instance_valid(current):
		if current.has_method("request_rebuild"):
			return current
		current = current.get_parent()
	return null

func _register_to_generator() -> void:
	var generator: Node = _find_generator()
	if is_instance_valid(generator):
		if not waypoint_changed.is_connected(generator._on_waypoint_changed):
			waypoint_changed.connect(generator._on_waypoint_changed)
		generator.request_rebuild()

func _unregister_from_generator() -> void:
	var generator: Node = _find_generator()
	if is_instance_valid(generator):
		if waypoint_changed.is_connected(generator._on_waypoint_changed):
			waypoint_changed.disconnect(generator._on_waypoint_changed)
		if generator.is_inside_tree() and not generator.is_queued_for_deletion():
			generator.request_rebuild()
