# deliveryMan.gd
class_name DeliveryMan
extends Interactable

## The zone this desk ships from. Assign in the inspector.
@export var delivery_zone: DeliveryZone

## Sends the driver off with everything on the pad.
func finish_delivery(delivered_items: Array[WineBox]) -> void:
	if delivered_items.is_empty():
		return
	
	# not sure if this should be here or in game.gd but:
	# TODO: stop round timer
	# TODO: check if we hit quota: handle not hitting quota = loss?
	# TODO: add money earned
	# TODO: start next phase, aka upgradeing phase
	
	for box in delivered_items:
		box.queue_free()

func can_interact(player: Player) -> bool:
	return true

func interact(player: Player) -> void:
	if not can_interact(player):
		return
	finish_delivery(delivery_zone.take_all())

func get_prompt() -> String:
	return "Send delivery (%d)" % delivery_zone.held_items.size()
