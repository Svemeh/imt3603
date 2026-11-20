class_name Player
extends CharacterBody3D


enum PlayerVariant {
	YELLOW,
	PURPLE,
	GREEN,
	BLUE
}

## Emitted after the normal station action. The popup manager listens to this
## so keyboard and controller interactions both open the matching window.
signal station_interacted(station: Interactable)

@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var acceleration: float = 25.0
@export var deceleration: float = 45.0
@export var rotation_speed: float = 10.0
## Seconds a player lies on the floor after falling
@export var fall_stun_time: float = 1.0
## Seconds you still can't run after stepping out of a spill
@export var spill_no_run_time: float = 2.0

@export var player_variant: PlayerVariant = PlayerVariant.YELLOW


@onready var yellow_model: Node3D = $VisualRoot/FarmerYellow
@onready var purple_model: Node3D = $VisualRoot/FarmerPurple
@onready var green_model: Node3D = $VisualRoot/FarmerGreen
@onready var blue_model: Node3D = $VisualRoot/FarmerBlue

## Where held items sit. Add a Marker3D child named HandMarker to player.tscn
@onready var hand_marker: Marker3D = $HandMarker
@onready var visual_root: Node3D = $VisualRoot

var animation_player: AnimationPlayer

var idle_animation: String
var walk_animation: String
var run_animation: String


var held_item: Item = null

var player_index := 0

var _in_range: Array[Interactable] = []
var _items_in_range: Array[Item] = []
## Spills the player is currently standing in
var _spills: Array = []
## Counts down after leaving a spill, no running while above 0
var _no_run_timer: float = 0.0
## Counts down while knocked over
var _stun_timer: float = 0.0
## Whether the player was running this physics frame
var _is_running: bool = false
var _fall_tween: Tween


func act(action: String) -> String:
	return "%s_%d" % [action, player_index]


func _ready() -> void:
	run_speed *= Modifiers.run_speed_multiplier
	fall_stun_time *= Modifiers.stun_time_multiplier
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
		if held_item is Broom:
			(held_item as Broom).sweep(self)
		else:
			try_interact()

	elif event.is_action_pressed(act("interact2")):
		if is_holding():
			if not try_give_item():
				drop_item()
		else:
			try_pickup()


func _physics_process(delta: float) -> void:
	_update_spill_state(delta)

	if _stun_timer > 0.0:
		_stun_timer -= delta

	var input := Input.get_vector(
		act("left"),
		act("right"),
		act("up"),
		act("down")
	)

	# Lying on the floor after a fall, no moving
	if is_stunned():
		input = Vector2.ZERO

	var direction := Vector3(input.x, 0.0, input.y).normalized()

	var is_moving := direction != Vector3.ZERO
	var is_running := is_moving and Input.is_action_pressed(act("run")) and can_run()
	_is_running = is_running

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

	if is_running:
		_knock_items_from_collided_players()

## Running into another player knocks both of you over. Both fall and
## drop what they hold, even if the other player was standing still
func _knock_items_from_collided_players() -> void:
	var hit_someone := false

	for i in get_slide_collision_count():
		var other := get_slide_collision(i).get_collider() as Player

		if other == null or other == self:
			continue

		hit_someone = true

		# The player who got hit always falls, even with empty hands
		other.crash()

	# The runner crashes as well
	if hit_someone:
		crash()

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
		# Update the popup after the action, so it sees the new machine state.
		station_interacted.emit(target)

## True when the player is carrying something
func is_holding() -> bool:
	return held_item != null

## Picks up the nearest loose item on the ground. Does nothing when hands
## are full or nothing is in range. Skips items that are locked in place
func try_pickup() -> void:
	if held_item != null:
		return

	var best: Item = null
	var best_stack: BarrelStack = null
	var best_dist := INF

	# Find the closest normal pickup.
	for item in _items_in_range:
		if not is_instance_valid(item) or not item.can_pick_up:
			continue

		var distance := global_position.distance_to(item.global_position)

		if distance < best_dist:
			best_dist = distance
			best = item

	# Check whether a barrel stack is closer.
	for target in _in_range:
		if not is_instance_valid(target):
			continue

		var stack := target as BarrelStack

		if stack == null or not stack.has_barrels():
			continue

		var distance := global_position.distance_to(stack.global_position)

		if distance < best_dist:
			best_dist = distance
			best_stack = stack

	# Take from the closest available source.
	if best_stack != null:
		best_stack.take_barrel(self)
	elif best != null:
		recieve_item(best)
		return

	for i in _in_range:
		if i is BarrelStack and i.take_barrel(self):
			return

## Takes an item into the player's hands. Returns false if hands are full
func recieve_item(item: Item) -> bool:
	if held_item != null:
		return false

	held_item = item
	item.freeze = true

	add_collision_exception_with(item)

	# While held, the item must not block other players (the wine crate is
	# on the world layer), or it pushes them away instead of a crash
	item.set_meta("ground_layer", item.collision_layer)
	item.collision_layer = item.collision_layer & ~1

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

	# Gives the item back the collision it had before it was picked up
	if item and item.has_meta("ground_layer"):
		item.collision_layer = item.get_meta("ground_layer")
		item.remove_meta("ground_layer")

	return item

## Drops the held item on the ground where the hands are
func drop_item(force: bool = false) -> void:
	if held_item == null or (not held_item.can_drop and not force):
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

## True while knocked over
func is_stunned() -> bool:
	return _stun_timer > 0.0

## No running while inside a spill or shortly after leaving one
func can_run() -> bool:
	return _spills.is_empty() and _no_run_timer <= 0.0

## Called by a Spill when the player steps into it.
## Running onto a spill makes you fall.
func enter_spill(spill: Spill) -> void:
	if spill in _spills:
		return
	_spills.append(spill)

	if _is_running:
		crash()

## Called by a Spill when the player steps out of it
func exit_spill(spill: Spill) -> void:
	_spills.erase(spill)
	if _spills.is_empty():
		_no_run_timer = spill_no_run_time

## Removes cleaned spills and counts down the no-run time
func _update_spill_state(delta: float) -> void:
	var had_spills := not _spills.is_empty()
	_spills = _spills.filter(func(s): return is_instance_valid(s))

	if had_spills and _spills.is_empty():
		_no_run_timer = spill_no_run_time
	elif _spills.is_empty() and _no_run_timer > 0.0:
		_no_run_timer -= delta

## Knocks the player over: they drop what they hold, it may spill,
## and they can't move for a moment. Used when sprinted into or
## when running onto a spill.
func crash() -> void:
	if is_stunned():
		return

	_stun_timer = fall_stun_time
	_is_running = false
	velocity = Vector3.ZERO
	_play_fall()

	if not is_holding():
		return

	var item := held_item
	var spill_radius := item.get_crash_spill_radius()
	var spill_pos := Vector3(
		hand_marker.global_position.x,
		global_position.y,
		hand_marker.global_position.z
	)

	drop_item(item is WineBox)

	# Item could not be dropped (e.g. the hammer)
	if held_item == item:
		return

	if spill_radius > 0.0:
		Spill.spawn(get_tree().current_scene, spill_pos, spill_radius)

	item.on_crashed()

## Tips the model forward and back up again
func _play_fall() -> void:
	if _fall_tween:
		_fall_tween.kill()
	_fall_tween = create_tween()
	_fall_tween.tween_property(visual_root, "rotation:x", deg_to_rad(75.0), 0.15)
	_fall_tween.tween_interval(maxf(fall_stun_time - 0.4, 0.0))
	_fall_tween.tween_property(visual_root, "rotation:x", 0.0, 0.25)
