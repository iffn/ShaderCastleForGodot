@tool
class_name BranchNode
extends Node3D

signal branch_changed

var _last_transform: Transform3D


# ==============================================================================
# Godot Built-ins
# ==============================================================================

func _ready() -> void:
	_last_transform = transform
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if not transform.is_equal_approx(_last_transform):
			_last_transform = transform
			_notify_change()


# ==============================================================================
# Public Functions
# ==============================================================================

# Public API for external node interactions can be added here as needed.


# ==============================================================================
# Private Functions
# ==============================================================================

func _notify_change() -> void:
	branch_changed.emit()


func _get_radius_multiplier() -> float:
	return scale.length() / Vector3.ONE.length()
