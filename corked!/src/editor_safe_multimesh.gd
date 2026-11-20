@tool
extends MultiMesh
## Godot #106950: reloading an embedded MultiMesh reuses its allocated resource.
## Release its old allocation before the loader restores format, flags and buffer.
func _reset_state() -> void:
	instance_count = 0
