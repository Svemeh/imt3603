extends Control

const PLAYER_BADGE := preload("res://scenes/ui/player_badge.tscn")

@onready var money_label: Label = $Design/Resources/Money/Value
@onready var quota_label: Label = $Design/Resources/Quota/Value
@onready var timer_bar: ProgressBar = $Design/Timer/TimerBar
@onready var timer_label: Label = $Design/Timer/TimeLabel
@onready var player_row: HBoxContainer = $Design/Players

## Layout is designed at the game's default width. Smaller windows scale the HUD
## as one group, keeping four badges between the plaques and the centred timer.
@export_range(0.75, 1.25, 0.05) var hud_scale: float = 1.0
var _roster_refresh_queued: bool = false

func _ready() -> void:
	resized.connect(_layout_hud)
	_layout_hud()
	# Game spawns players after HUD is ready and recreates them between rounds.
	# Watch actual player nodes rather than drawing empty slots from MAX_PLAYERS.
	get_parent().child_entered_tree.connect(_on_player_tree_changed)
	get_parent().child_exiting_tree.connect(_on_player_tree_changed)
	_queue_roster_refresh()

## Keeps the timer at the screen midpoint and the top-right area free for buildings.
func _layout_hud() -> void:
	var design: Control = $Design
	var fit := minf(hud_scale, size.x / 1152.0)
	design.scale = Vector2.ONE * fit
	design.size = size / maxf(fit, 0.01)
	$Design/Timer.position.x = (design.size.x - $Design/Timer.size.x) * 0.5

## Only roster changes trigger a rebuild; ordinary world items do not affect HUD.
func _on_player_tree_changed(node: Node) -> void:
	if node is Player:
		_queue_roster_refresh()

## Defer until players have entered or exited the tree, combining same-frame spawns.
func _queue_roster_refresh() -> void:
	if _roster_refresh_queued:
		return
	_roster_refresh_queued = true
	_refresh_players.call_deferred()

## Shows exactly one colour-matched portrait per player currently in the game.
func _refresh_players() -> void:
	_roster_refresh_queued = false
	# A round reset can detach this HUD before a queued roster refresh runs.
	if not is_inside_tree() or get_parent() == null:
		return
	for badge in player_row.get_children():
		player_row.remove_child(badge)
		badge.queue_free()
	var players: Array[Player] = []
	for child in get_parent().get_children():
		if child is Player and child.is_inside_tree() and not child.is_queued_for_deletion():
			players.append(child)
	players.sort_custom(func(a: Player, b: Player): return a.player_index < b.player_index)
	for player in players:
		var badge := PLAYER_BADGE.instantiate()
		player_row.add_child(badge)
		badge.setup(player.player_index, player.player_variant)

## Updates the wallet value without baking numbers or text into the artwork.
func update_money(amount: int) -> void:
	money_label.text = str(amount)
	_fit_value(money_label)

## Loaded bottles against the current quota, including quotas that grow each round.
func update_quota(loaded: int, target: int) -> void:
	quota_label.text = "%d/%d" % [loaded, target]
	_fit_value(quota_label)

## Reduce the number font for large wallets/quotas before they reach the frame edge.
func _fit_value(label: Label) -> void:
	var font := label.get_theme_font("font")
	var font_size := 28
	# Label minimum width can grow with text, so use the fixed number slots.
	var available_width := 77.0 if label == money_label else 89.0
	while font_size > 16 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)

## Shows remaining time as mm:ss and drains the bar towards zero. Ceiling prevents
## displaying 00:00 before the round ends; clamping also handles late timer updates.
func update_timer(time_left: float, round_duration: float) -> void:
	var duration := maxf(round_duration, 0.0)
	var remaining := clampf(time_left, 0.0, duration)
	timer_bar.max_value = maxf(duration, 1.0)
	timer_bar.value = remaining
	var seconds := ceili(remaining)
	@warning_ignore("integer_division")
	var minutes := seconds / 60
	timer_label.text = "%02d:%02d" % [minutes, seconds % 60]
