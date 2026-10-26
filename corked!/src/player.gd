# player.gd
class_name Player
extends CharacterBody3D


enum PlayerVariant {
	YELLOW,
	PURPLE,
	GREEN,
	BLUE
}


@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var acceleration: float = 25.0
@export var deceleration: float = 45.0
@export var rotation_speed: float = 10.0

@export var player_variant: PlayerVariant = PlayerVariant.YELLOW


@onready var yellow_model: Node3D = $VisualRoot/FarmerYellow
@onready var purple_model: Node3D = $VisualRoot/FarmerPurple
@onready var green_model: Node3D = $VisualRoot/FarmerGreen
@onready var blue_model: Node3D = $VisualRoot/FarmerBlue

## Where held items sit. Add a Marker3D child named HandMarker to player.tscn
@onready var hand_marker: Marker3D = $HandMarker

var animation_player: AnimationPlayer

var idle_animation: String
var walk_animation: String
var run_animation: String


var held_item: Item = null

var player_index := 0

var _in_range: Array[Interactable] = []
var _items_in_range: Array[Item] = []


func act(action: String) -> String:
	return "%s_%d" % [action, player_index]


func _ready() -> void:
	setup_player_variant()
	animation_player.play(idle_animation)


func setup_player_variant() -> void:
	yellow_model.visible = false
	purple_model.visible = false
	green_model.visible = false
	blue_model.visible = false

	match player_variant:
		PlayerVariant.YELLOW:
			yellow_model.visible = true
			animation_player = yellow_model.get_node("AnimationPlayer")

			idle_animation = "shared/Idle_3"
			walk_animation = "Walking"
			run_animation = "Running"

		PlayerVariant.PURPLE:
			purple_model.visible = true
			animation_player = purple_model.get_node("AnimationPlayer")

			idle_animation = "shared/Idle_3"
			walk_animation = "Walking"
			run_animation = "Running"

		PlayerVariant.GREEN:
			green_model.visible = true
			animation_player = green_model.get_node("AnimationPlayer")

			idle_animation = "shared/Idle_3"
			walk_animation = "Walking"
			run_animation = "Running"

		PlayerVariant.BLUE:
			blue_model.visible = true
			animation_player = blue_model.get_node("AnimationPlayer")

			idle_animation = "shared/Idle_3"
			walk_animation = "Walking"
			run_animation = "Running"


## "interact" drives stations that stay put (vines, presses, barrels).
## "interact2" is the hands button: drop what is held, otherwise pick up
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(act("interact")):
		try_interact()

	elif event.is_action_pressed(act("interact2")):
		if is_holding():
			if not try_give_item():
				drop_item()
		else:
			try_pickup()


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(
		act("left"),
		act("right"),
		act("up"),
		act("down")
	)

	var direction := Vector3(input.x, 0.0, input.y).normalized()

	var is_moving := direction != Vector3.ZERO
	var is_running := is_moving and Input.is_action_pressed(act("run"))

	if is_running:
		if animation_player.current_animation != run_animation:
			animation_player.play(run_animation, 0.15)

	elif is_moving:
		if animation_player.current_animation != walk_animation:
			animation_player.play(walk_animation, 0.15)

	else:
		if animation_player.current_animation != idle_animation:
			animation_player.play(idle_animation, 0.15)

	var speed := walk_speed

	if is_running:
		speed = run_speed

	var target_velocity := direction * speed

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

	if is_moving:
		var target_angle := atan2(direction.x, direction.z)

		rotation.y = lerp_angle(
			rotation.y,
			target_angle,
			rotation_speed * delta
		)

	move_and_slide()

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

## Finds nearest target
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
## are full or nothing is in range. Skips items that are locked in place
func try_pickup() -> void:
	if held_item != null:
		return

	var best: Item = null
	var best_dist := INF

	for i in _items_in_range:
		if not i.can_pick_up:
			continue

		var d := global_position.distance_to(i.global_position)

		if d < best_dist:
			best_dist = d
			best = i

	if best:
		recieve_item(best)

## Takes an item into the player's hands. Returns false if hands are full
func recieve_item(item: Item) -> bool:
	if held_item != null:
		return false

	held_item = item
	item.freeze = true

	add_collision_exception_with(item)

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

	item.freeze = false

	remove_collision_exception_with(item)

	item.global_position = world_pos

## Gives the held item to the nearest interactable that accepts it
func try_give_item() -> bool:
	var best: Interactable = null
	var best_dist := INF

	for i in _in_range:
		if not i.can_accept_item(held_item):
			continue

		var d := global_position.distance_to(i.global_position)

		if d < best_dist:
			best_dist = d
			best = i

	if best == null:
		return false

	best.accept_item(self)

	return true
