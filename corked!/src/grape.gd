class_name Grape
extends Item

## The Grape item: created when a vine finishes harvesting and placed straight
## into the player's hands, then carried and eventually dropped into a Container
##
## Grape only holds grape-specific data. It never moves or parents itself,
## PlayerManager does that, including when the grape gets knocked out of a
## players hand and dropped on the ground.

## How many grapes this item represents. A barrel will sum this up as grapes
## are dropped in
@export var amount: int = 1

## Placeholder for later work (e.g. "merlot", "chardonnay"). Not used yet.
## @export var variety: String = "generic"

## Placeholder for later work (0.0 - 1.0). Not used yet.
## @export var quality: float = 1.0

func _ready() -> void:
	display_name = "Grapes"

func setup(p_amount: int) -> void:
	amount = p_amount
	## variety = p_variety
	## quality = p_quality

func get_display_name() -> String:
	return "%s x%d" % [display_name, amount]
