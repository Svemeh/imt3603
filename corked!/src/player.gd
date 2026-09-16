# player.gd
class_name Player
extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0

@export var acceleration: float = 25.0
@export var deceleration: float = 45.0
@export var rotation_speed: float = 10.0

@onready var animation_player: AnimationPlayer = $VisualRoot/FarmerYellow/AnimationPlayer

## Where held items sit. Add a Marker3D child named HandMarker to player.tscn,
## roughly chest height and slightly forward.
@onready var hand_marker: Marker3D = $HandMarker

const IDLE_ANIMATION := "Meshy_AI_Animation_Idle_3_withSkin/Idle_3"
const WALK_ANIMATION := "Meshy_AI_Farmer_Tan_Rigged_biped_Animation_Walking_withSkin/Armature|walking_man|baselayer"
const RUN_ANIMATION := "Meshy_AI_Animation_Running_withSkin/Running"

## item currently held
var held_item: Item = null

func _ready() -> void:
	animation_player.play(IDLE_ANIMATION)

## "interact" drives stations that stay put (vines, presses, barrels).
## "interact2" is the hands button: drop what is held, otherwise pick up
## the nearest loose item on the ground.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		try_interact()
	
	elif event.is_action_pressed("interact2"):
		if is_holding():
			drop_item()
		else:
			try_pickup()

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

## Loose items lying on the ground within range
var _items_in_range: Array[Item] = []

## Appends new interactable or loose item to the matching in range array
func _on_area_entered(body: Node3D) -> void:
	if body is Interactable:
		_in_range.append(body)
	
	elif body is Item:
		_items_in_range.append(body)

## Removes the node from whichever in range array holds it
func _on_area_exited(body: Node3D) -> void:
	if body is Interactable:
		_in_range.erase(body)
	elif body is Item:
		_items_in_range.erase(body)

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

## True when the player is carrying something
func is_holding() -> bool:
	return held_item != null

## Picks up the nearest loose item on the ground. Does nothing when hands
## are full or nothing is in range.
func try_pickup() -> void:
	if held_item != null:
		return
	
	var best: Item = null
	var best_dist := INF
	for i in _items_in_range:
		var d := global_position.distance_to(i.global_position)
		if d < best_dist:
			best_dist = d
			best = i
	
	if best:
		recieve_item(best)

## Takes an item into the player's hands. Returns false if hands are full,
## so the caller knows the handover did not happen.
## Items spawned by an interactable have no parent yet, so add_child is used
## in that case and reparent in every other.
func recieve_item(item: Item) -> bool:
	if held_item != null:
		return false
	
	held_item = item
	_items_in_range.erase(item)
	
	if item.get_parent() == null:
		hand_marker.add_child(item)
	else:
		item.reparent(hand_marker)
	
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	return true

## Hands over the held item without placing it anywhere. The caller becomes
## responsible for reparenting it. Used by Interactables.
func transfer_item() -> Item:
	var item := held_item
	held_item = null
	return item

## Drops the held item on the ground where the hands are
func drop_item() -> void:
	if held_item == null:
		return
	
	var item := transfer_item()
	var world_pos := hand_marker.global_position
	
	item.reparent(get_tree().current_scene)
	item.global_position = world_pos
