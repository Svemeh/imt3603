# grapevine.gd
class_name GrapeVine
extends Interactable

## A harvestable vine. Interacting with it creates one Grape item and hands it
## straight to the player. Each vine gives one grape.

const GRAPE_SCENE: PackedScene = preload("res://scenes/grape.tscn")
@onready var timer = $Timer

## How many grapes a single harvest from this vine yields
@export var yield_amount: int = 1

## Whether this vine has a grape ready to harvest
var has_grape: bool = true

## Once cooldown timer finishes grape has regrown.
## Timer is found as a gd Timer node right under the grapevine node
func _on_my_timer_timeout():
	has_grape = true

## Can only be harvested if vine has grape and player hands are free
func can_interact(player: Player) -> bool:
	return (has_grape and not player.is_holding())

func interact(player: Player) -> void:
	if not can_interact(player):
		return
	
	var grape: Grape = GRAPE_SCENE.instantiate()
	grape.setup(yield_amount)
	player.recieve_item(grape)
	
	# Bush can not be harvested again before the timer ends
	has_grape = false
	timer.start()
	

func get_prompt() -> String:
	return "Harvest"
