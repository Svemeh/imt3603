class_name BottlingStation
extends Interactable

const WINE_BOX_SCENE: PackedScene = preload("res://scenes/wine_box.tscn")

## The barrel currently docked at the station, if any
var barrel: Barrel = null

## Connect this stations own item detection Area3D body_entered signal
## to this function (NOT the players interact range area)
func _on_item_zone_body_entered(body: Node3D) -> void:
	if body is Barrel and barrel == null:
		barrel = body

## Connect the same Area3Ds body_exited signal here
func _on_item_zone_body_exited(body: Node3D) -> void:
	if body == barrel:
		barrel = null

func can_interact(player: Player) -> bool:
	if player.is_holding():
		return false
	if barrel == null:
		return false
	return barrel.juice_amount > 0

func interact(player: Player) -> void:
	if not can_interact(player):
		return
	
	barrel.juice_amount -= 1
	
	var box: WineBox = WINE_BOX_SCENE.instantiate()
	player.recieve_item(box)

func get_prompt() -> String:
	if barrel == null:
		return "Place a barrel here"
	if barrel.juice_amount <= 0:
		return "No wine to bottle"
	return "Bottle wine"
