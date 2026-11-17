# spill.gd
class_name Spill
extends Area3D

## A puddle of wine on the floor. You can't run inside it, and running onto it
## makes you fall. Takes a few broom sweeps to clean up.

const WINE_SPILL_SHADER := preload("res://assets/shaders/wine_spill.gdshader")

## Spill sizes (radius in metres)
const NORMAL_RADIUS := 0.75   # normal item dropped in a crash
const BIG_RADIUS := 1.35      # barrel
const LARGE_RADIUS := 1.5     # crate of bottles breaking

## Sweeps with the broom needed to remove it
const SWEEPS_TO_CLEAN := 4

var radius: float = NORMAL_RADIUS

var _sweeps_left: int = SWEEPS_TO_CLEAN
var _fade: float = 1.0
var _material: ShaderMaterial
var _fade_tween: Tween


## Creates a spill on the floor at "at". Added deferred because this is often
## called from inside a collision signal, where Godot blocks adding areas
static func spawn(parent: Node, at: Vector3, spill_radius: float) -> Spill:
	var spill := Spill.new()
	spill.radius = spill_radius
	spill.monitorable = false
	spill.position = at
	parent.add_child.call_deferred(spill)
	return spill


func _ready() -> void:
	add_to_group("spills")

	# Only detects bodies (players are on layer 1), is not detected itself
	collision_layer = 0
	collision_mask = 1

	rotation.y = randf() * TAU

	# Hitbox, a bit smaller than the visual so the edges feel fair
	var shape := CylinderShape3D.new()
	shape.radius = radius * 0.85
	shape.height = 1.0
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.5
	add_child(col)

	# Visual
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * radius * 2.0

	_material = ShaderMaterial.new()
	_material.shader = WINE_SPILL_SHADER
	_material.set_shader_parameter("seed", randf() * 100.0)
	_material.set_shader_parameter("fade", 1.0)

	var mesh := MeshInstance3D.new()
	mesh.mesh = plane
	mesh.material_override = _material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position.y = 0.02   # just above the floor so it does not flicker
	add_child(mesh)

	# Quick "splash" grow-in
	mesh.scale = Vector3.ONE * 0.2
	create_tween().tween_property(mesh, "scale", Vector3.ONE, 0.3) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).enter_spill(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		(body as Player).exit_spill(self)


## True while there is still something left to clean
func can_sweep() -> bool:
	return _sweeps_left > 0


## One broom sweep. Fades a bit each time, removed on the last sweep
func sweep() -> void:
	if not can_sweep():
		return

	_sweeps_left -= 1
	var target := float(_sweeps_left) / float(SWEEPS_TO_CLEAN)

	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_fade, _fade, target, 0.3)

	if _sweeps_left == 0:
		_fade_tween.tween_callback(queue_free)


func _set_fade(value: float) -> void:
	_fade = value
	_material.set_shader_parameter("fade", value)
