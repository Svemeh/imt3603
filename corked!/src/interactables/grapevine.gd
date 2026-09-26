# grapevine.gd
class_name GrapeVine
extends Interactable

## A harvestable vine. Interacting with it creates one Grape item and hands it
## straight to the player. Each vine gives one grape.

const GRAPE_SCENE: PackedScene = preload("res://scenes/items/grape.tscn")
@onready var timer = $Timer

## How many grapes a single harvest from this vine yields
@export var yield_amount: int = 1

## Whether this vine has a grape ready to harvest
var has_grape: bool = true

## Once cooldown timer finishes grape has regrown.
## Timer is found as a gd Timer node right under the grapevine node
func _on_my_timer_timeout():
	has_grape = true
	toggleGrapeVisibility() # This whole functions must be reworked when we have change the model

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
	toggleGrapeVisibility() # This whole functions must be reworked when we have change the model
	timer.start()
	

func get_prompt() -> String:
	return "Harvest"

## This whole functions must be reworked when we have change the model
func toggleGrapeVisibility() -> void: 
	$Vine_station_3_plants/Plant_1/Harvest_Plant1_Cluster1.visible = has_grape
	$Vine_station_3_plants/Plant_1/Harvest_Plant1_Cluster2.visible = has_grape
	$Vine_station_3_plants/Plant_2/Harvest_Plant2_Cluster1.visible = has_grape
	$Vine_station_3_plants/Plant_2/Harvest_Plant2_Cluster2.visible = has_grape
	$Vine_station_3_plants/Plant_3/Harvest_Plant3_Cluster1.visible = has_grape
	$Vine_station_3_plants/Plant_3/Harvest_Plant3_Cluster2.visible = has_grape
