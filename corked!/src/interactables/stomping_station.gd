# stomping_station.gd
class_name StompingStation
extends Interactable

## Mash progress on the current grape changed, 0.0 -> 1.0
signal mash_changed(ratio: float)
## Barrel fill level changed, 0.0 -> 1.0
signal juice_changed(ratio: float)
## A player stomped once (for the left/right feet in the window)
signal stomped
## A grape was fully stomped (resets the bar in the window)
signal grape_finished


## Stomps needed to turn one grape into juice
@export var stomps_required: int = 10
## Stomps lost per decay tick ("damage")
@export var decay_per_tick: float = 0.1
## Seconds between decay ticks
@export var decay_interval: float = 0.1

## Grape fill visual
@export var max_grape_capacity: int = 4
@export var empty_grape_y: float = 0.005
@export var full_grape_y: float = 0.305
@onready var grape_fill: Node3D = $GrapeFill

## Where a docked barrel sits
@onready var barrel_marker: Marker3D = $barrelMarker
## Wet squish played on every stomp
@onready var stomp_sound: AudioStreamPlayer = $StompSound

## Grapes handed to this station, stomped one at a time
var _grapes: Array[Grape] = []

## Barrel currently docked at this station, if any
var barrel: Barrel = null

## How many stomps on the current grape so far
var _mash: float = 0.0
## Time since the last decay tick
var _tick_time: float = 0.0

func _ready() -> void:
	update_grape_visual()
	_connect_stomp_popup()

## Loses decay_per_tick stomps every decay_interval seconds
func _process(delta: float) -> void:
	if _mash <= 0.0:
		_tick_time = 0.0
		return
	_tick_time += delta
	while _tick_time >= decay_interval:
		_tick_time -= decay_interval
		_mash = maxf(_mash - decay_per_tick, 0.0)
	mash_changed.emit(_mash / stomps_required)

func update_grape_visual() -> void:
	var grape_count: int = _grapes.size()

	if grape_count <= 0:
		grape_fill.visible = false
		return

	grape_fill.visible = true

	var fill_ratio: float = float(grape_count - 1) / float(max_grape_capacity - 1)

	grape_fill.position.y = lerp(
		empty_grape_y,
		full_grape_y,
		fill_ratio
	)

## Clears the barrel if the player picked it back up
func _check_barrel() -> void:
	if barrel and barrel.get_parent() != barrel_marker:
		barrel = null
		_mash = 0.0
		mash_changed.emit(0.0)
		_emit_juice()

func can_accept_item(item: Item) -> bool:
	_check_barrel()
	if item is Grape:
		return _grapes.size() < max_grape_capacity
	return item is Barrel and barrel == null

func accept_item(player: Player) -> void:
	var item := player.transfer_item()
	player.remove_collision_exception_with(item)

	if item is Barrel:
		barrel = item
		item.reparent(barrel_marker)
		item.position = Vector3.ZERO
		item.rotation = Vector3.ZERO
		item.freeze = true
		_emit_juice()
		return

	item.reparent(self)
	item.visible = false
	item.process_mode = Node.PROCESS_MODE_DISABLED
	_grapes.append(item)
	update_grape_visual()

func can_interact(_player: Player) -> bool:
	_check_barrel()
	if _grapes.is_empty() or barrel == null:
		return false
	return barrel.juice_amount < barrel.MAX_CAPACITY

func interact(player: Player) -> void:
	if not can_interact(player):
		return
	
	# every press is one stomp
	_mash = minf(_mash + 1.0, stomps_required)
	stomped.emit()
	_play_stomp_sound()
	mash_changed.emit(_mash / stomps_required)
	if _mash < stomps_required:
		return
	
	# 10 stomps reached, this grape becomes juice
	var grape: Grape = _grapes.pop_front()
	var remaining_capacity = barrel.MAX_CAPACITY - barrel.juice_amount
	barrel.add_juice(min(grape.amount, remaining_capacity))

	grape.queue_free()
	_mash = 0.0
	grape_finished.emit()
	_emit_juice()
	update_grape_visual()

## Tells the window how full the docked barrel is
func _emit_juice() -> void:
	var ratio := 0.0
	if barrel:
		ratio = float(barrel.juice_amount) / barrel.MAX_CAPACITY
	juice_changed.emit(ratio)

func _connect_stomp_popup() -> void:
	var mount := get_node_or_null("MinigameWindowPreview")
	if mount == null or not mount.window.has_method("set_mash"):
		return
	var popup = mount.window
	mash_changed.connect(popup.set_mash)
	juice_changed.connect(popup.set_juice)
	stomped.connect(popup.stomp)
	grape_finished.connect(popup.finish_grape)

func _play_stomp_sound() -> void:
	stomp_sound.pitch_scale = randf_range(0.9, 1.1)
	stomp_sound.play()

func get_prompt() -> String:
	_check_barrel()
	if _grapes.is_empty():
		return "Put a grape in the press"
	if barrel == null:
		return "Place a barrel here"
	if barrel.juice_amount >= barrel.MAX_CAPACITY:
		return "Barrel is full"
	return "Stomp (%d/%d) - %d grapes" % [_mash, stomps_required, _grapes.size()]
