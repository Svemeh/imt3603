extends Control

## Portraits are rendered from the actual player models, not alternate character art.
const PORTRAITS := [
	preload("res://scenes/ui/hud_assets/portrait_1.png"),
	preload("res://scenes/ui/hud_assets/portrait_2.png"),
	preload("res://scenes/ui/hud_assets/portrait_3.png"),
	preload("res://scenes/ui/hud_assets/portrait_4.png")
]
## Matches PlayerVariant.YELLOW, PURPLE, GREEN and BLUE respectively.
const COLOURS := [Color("e8af24"), Color("b928df"), Color("36ac45"), Color("258fdf")]

## Keeps the real player number even when another slot is empty or a player leaves.
func setup(player_index: int, variant: int) -> void:
	var colour: Color = COLOURS[clampi(variant, 0, COLOURS.size() - 1)]
	$Portrait.texture = PORTRAITS[clampi(variant, 0, PORTRAITS.size() - 1)]
	$PlayerLabel.text = "P%d" % (player_index + 1)
	# Duplicate styles so changing one badge never recolours the other players.
	var ring := $Ring.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	ring.border_color = colour
	ring.bg_color = colour.darkened(0.78)
	$Ring.add_theme_stylebox_override("panel", ring)
	var tab := $Tab.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	tab.bg_color = colour.darkened(0.12)
	tab.border_color = colour.lightened(0.25)
	$Tab.add_theme_stylebox_override("panel", tab)
