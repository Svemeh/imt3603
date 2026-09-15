# player.gd
class_name Player
extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0

@export var acceleration: float = 25.0
@export var deceleration: float = 45.0
@export var rotation_speed: float = 10.0

@onready var animation_player: AnimationPlayer = $VisualRoot/FarmerYellow/AnimationPlayer

const IDLE_ANIMATION := "Meshy_AI_Animation_Idle_3_withSkin/Idle_3"
const WALK_ANIMATION := "Meshy_AI_Farmer_Tan_Rigged_biped_Animation_Walking_withSkin/Armature|walking_man|baselayer"
const RUN_ANIMATION := "Meshy_AI_Animation_Running_withSkin/Running"

func _ready() -> void:
	animation_player.play(IDLE_ANIMATION)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)

	var direction := Vector3(input.x, 0.0, input.y).normalized()

	var is_moving := direction != Vector3.ZERO
	var is_running := is_moving and Input.is_action_pressed("run")


	# ANIMATIONS
	if is_running:
		if animation_player.current_animation != RUN_ANIMATION:
			animation_player.play(RUN_ANIMATION, 0.15)

	elif is_moving:
		if animation_player.current_animation != WALK_ANIMATION:
			animation_player.play(WALK_ANIMATION, 0.15)

	else:
		if animation_player.current_animation != IDLE_ANIMATION:
			animation_player.play(IDLE_ANIMATION, 0.15)


	# MOVEMENT SPEED
	var speed := walk_speed

	if is_running:
		speed = run_speed

	var target_velocity := direction * speed

	# ACCELERATION / DECELERATION
	if is_moving:
		velocity.x = move_toward(
			velocity.x,
			target_velocity.x,
			acceleration * delta
		)

		velocity.z = move_toward(
			velocity.z,
			target_velocity.z,
			acceleration * delta
		)

	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			deceleration * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			deceleration * delta
		)

	# ROTATE PLAYER TOWARDS MOVEMENT DIRECTION
	if is_moving:
		var target_angle := atan2(direction.x, direction.z)

		rotation.y = lerp_angle(
			rotation.y,
			target_angle,
			rotation_speed * delta
		)

	move_and_slide()


## Array storing all interactables within range
var _in_range: Array[Interactable] = []

## Appends new interactable to in range array
func _on_area_entered(body: Node3D) -> void:
	if body is Interactable:
		_in_range.append(body)

## Removes interactable in array
func _on_area_exited(body: Node3D) -> void:
	_in_range.erase(body)

## Finds a target to interact with
func _get_target() -> Interactable:
	var best: Interactable = null
	var best_dist := INF
	for i in _in_range:
		if not i.can_interact(self):
			continue
		var d := global_position.distance_to(i.global_position)
		if d < best_dist:
			best_dist = d
			best = i
	return best

## attempts to interact with closest interactable
func try_interact() -> void:
	var target := _get_target()
	if target:
		target.interact(self)
