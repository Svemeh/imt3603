extends CanvasLayer

## Raised once Skip is pressed. Game rebuilds the round beneath this overlay.
signal next_round_requested

## Fade duration is adjustable for presentation or faster development checks.
@export_range(0.0, 2.0, 0.05) var fade_duration: float = 0.5

@onready var overlay: Control = $Overlay
@onready var summary: Control = %Summary
@onready var computer: Control = %Computer
@onready var continue_button: Button = %ContinueButton
@onready var skip_button: Button = %SkipButton

## Blocks repeated confirmation while fading or rebuilding the world.
var _busy: bool = false
var _screen: StringName = &"hidden"

func _ready() -> void:
	overlay.hide()
	computer.resized.connect(_fit_computer)
	_fit_computer()
	continue_button.pressed.connect(_show_computer)
	skip_button.pressed.connect(_request_next_round)

## Called only once the driver and truck have finished leaving the map.
## This layer processes while paused; the gameplay world beneath it does not.
func show_round_over(round_number: int, bottles: int, earned: int, balance: int) -> void:
	_screen = &"summary"
	_busy = true
	# The computer uses an in-game evening clock; show the completed day below it.
	# Desktop icons are decorative placeholders until upgrade UI is implemented.
	%DesktopDay.text = "DAY %d" % round_number
	%RoundLabel.text = "ROUND %d COMPLETE" % round_number
	%BottlesValue.text = str(bottles)
	%EarnedValue.text = "$%d" % earned
	%BalanceValue.text = "$%d" % balance
	summary.show()
	computer.hide()
	continue_button.disabled = true
	overlay.modulate.a = 0.0
	overlay.show()
	await _fade(overlay, 1.0)
	continue_button.disabled = false
	_busy = false
	continue_button.grab_focus()

## Keeps the computer display intentionally empty for the later upgrade work.
## The Skip button sits below the monitor, outside its blank screen.
func _show_computer() -> void:
	if _busy or _screen != &"summary":
		return
	_busy = true
	continue_button.release_focus()
	await _fade(summary, 0.0)
	summary.hide()
	summary.modulate.a = 1.0
	computer.modulate.a = 0.0
	computer.show()
	_fit_computer()
	skip_button.disabled = true
	_screen = &"computer"
	await _fade(computer, 1.0)
	skip_button.disabled = false
	_busy = false
	skip_button.grab_focus()

## Disable confirmation before emitting so double presses cannot skip two rounds.
func _request_next_round() -> void:
	if _busy or _screen != &"computer":
		return
	_busy = true
	skip_button.disabled = true
	skip_button.release_focus()
	next_round_requested.emit()

## Game calls this after all fresh round nodes have been added and connected.
## Gameplay stays paused until the fade has fully revealed the restored world.
func reveal_next_round() -> void:
	await _fade(overlay, 0.0)
	overlay.hide()
	computer.hide()
	_screen = &"hidden"
	_busy = false

## Accept mouse clicks, Enter/Space and either station action on a controller.
## Consume confirmation here so it cannot also operate a machine underneath.
func _input(event: InputEvent) -> void:
	if not overlay.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("interact2") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if event.is_echo() or _busy:
			return
		if _screen == &"summary":
			_show_computer()
		elif _screen == &"computer":
			_request_next_round()

## The overlay inherits PROCESS_MODE_ALWAYS so these tweens also run while paused.
func _fade(control: Control, alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", alpha, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


## Keep the illustrated monitor and desk in proportion at any window size.
## This only scales the computer presentation; the recap uses normal containers.
func _fit_computer() -> void:
	var design: Control = computer.get_node("Design")
	var fit := minf(computer.size.x / 1152.0, computer.size.y / 648.0)
	design.scale = Vector2.ONE * fit
	design.position = (computer.size - Vector2(1152, 648) * fit) * 0.5

	# Extend the office desk across any extra space around the fitted artwork.
	# The opaque OfficeWall fills the entire viewport so gameplay never shows here.
	var desk: ColorRect = computer.get_node("DeskExtension")
	desk.anchor_top = 0.0
	desk.offset_top = design.position.y + 550.0 * fit
