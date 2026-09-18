# delivery_zone.gd
class_name DeliveryZone
extends Interactable

## Wine boxes dropped off but not yet sent away.
## Holds the actual nodes so different wine types can be told apart. 
## If we later want to differentiate between wine quality or amount or type
var held_items: Array[WineBox] = []

## Accepts one wine box onto the pad.
func _handle_delivery(delivered_item: WineBox) -> void:
	held_items.append(delivered_item)
	delivered_item.reparent(self)

## Hands everything over to the caller and empties the pad.
func take_all() -> Array[WineBox]:
	var items := held_items.duplicate()
	held_items.clear()
	return items

## Returns true if delivery_zone is empty
func is_empty() -> bool:
	return held_items.is_empty()

## Only accepts wine boxes, and only from a player holding one.
func can_interact(player: Player) -> bool:
	return player.is_holding() and player.held_item is WineBox

func interact(player: Player) -> void:
	if not can_interact(player):
		return
	_handle_delivery(player.transfer_item())

func get_prompt() -> String:
	return "Drop off wine (%d)" % held_items.size()
