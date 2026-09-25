# fermentation_station.gd
class_name FermentationStation
extends Interactable

## Player pours juice from a held barrel into the station. After fermenting
## (timer for now, minigame later) the juice becomes wine 1:1 inside the
## station's own barrel. That barrel is locked until it is full.

const BARREL_SCENE: PackedScene = preload("res://scenes/barrel.tscn")

@onready var ferment_timer: Timer = $FermentTimer
@onready var barrel_marker: Marker3D = $BarrelMarker

## The barrel sitting in the station that wine is poured into
var output_barrel: Barrel = null

## Juice poured in that has not finished fermenting yet
var _fermenting_amount: int = 0

func _ready() -> void:
	_spawn_output_barrel()

## Spawns a new barrel as soon as the finished one has been carried away
func _physics_process(_delta: float) -> void:
	if output_barrel == null or not is_instance_valid(output_barrel) \
			or output_barrel.get_parent() != barrel_marker:
		_spawn_output_barrel()

func _spawn_output_barrel() -> void:
	output_barrel = BARREL_SCENE.instantiate()
	output_barrel.is_wine = true
	output_barrel.can_pick_up = false
	barrel_marker.add_child(output_barrel)

## Space left in the output barrel, counting juice that is still fermenting
func _free_space() -> int:
	return output_barrel.MAX_CAPACITY - output_barrel.juice_amount - _fermenting_amount

## Only accepts a held barrel with juice in it (not wine), if there is room
func can_interact(player: Player) -> bool:
	if output_barrel == null or not player.is_holding():
		return false
	var held := player.held_item as Barrel
	if held == null or held.is_wine or held.juice_amount <= 0:
		return false
	return _free_space() > 0

## Pours as much juice as fits. The player keeps the (now emptier) barrel.
func interact(player: Player) -> void:
	if not can_interact(player):
		return
	
	var held := player.held_item as Barrel
	var amount := mini(held.juice_amount, _free_space())
	held.juice_amount -= amount
	_fermenting_amount += amount
	
	if ferment_timer.is_stopped():
		ferment_timer.start()

## Connect FermentTimer's timeout signal to this.
## Later the minigame can call _finish_fermenting() directly instead.
func _on_ferment_timer_timeout() -> void:
	_finish_fermenting()

## Turns all fermenting juice into wine, 1 to 1. Unlocks the barrel when full.
func _finish_fermenting() -> void:
	output_barrel.add_juice(_fermenting_amount)
	_fermenting_amount = 0
	
	if output_barrel.juice_amount >= output_barrel.MAX_CAPACITY:
		output_barrel.can_pick_up = true

func get_prompt() -> String:
	if output_barrel == null:
		return "No barrel"
	if output_barrel.juice_amount >= output_barrel.MAX_CAPACITY:
		return "Wine ready, pick up the barrel"
	if not ferment_timer.is_stopped():
		return "Fermenting... (%d)" % _fermenting_amount
	return "Pour juice (%d/%d)" % [output_barrel.juice_amount, output_barrel.MAX_CAPACITY]
