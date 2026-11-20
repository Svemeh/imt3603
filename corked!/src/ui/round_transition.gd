extends CanvasLayer

## Raised once Skip is pressed. Game rebuilds the round beneath this overlay.
signal next_round_requested
signal modifier_chosen(modifier: Dictionary, remove_debuff: bool)

const MENU_BUTTON := preload("res://assets/ui/menu_button.tscn")
const TITLE_COLOR := Color(1, 0.945, 0.816)
const BUFF_COLOR := Color(0.55, 0.9, 0.5)
const DEBUFF_COLOR := Color(1, 0.5, 0.45)
const HEADER_COLOR := Color(0.05, 0.12, 0.2)

## Fade duration is adjustable for presentation or faster development checks.
@export_range(0.0, 2.0, 0.05) var fade_duration: float = 0.5

@onready var overlay: Control = $Overlay
@onready var summary: Control = %Summary
@onready var computer: Control = %Computer
@onready var continue_button: Button = %ContinueButton
## Plays while the round-won screen is shown
@onready var round_won_sound: AudioStreamPlayer = $RoundWonSound

## Blocks repeated confirmation while fading or rebuilding the world.
var _busy: bool = false
var _screen: StringName = &"hidden"
var _balance: int = 0
var _choice_root: Control
var _first_button: Button
var _grid: Array = []
var _confirm_armed: bool = false
var _arm_at_msec: int = 0

const ARM_DELAY_MSEC := 400
const CONFIRM_ACTIONS := ["interact"]
var _col: int = 0
var _row: int = 0

const DIRECTIONS := {
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
}

func _ready() -> void:
	overlay.hide()
	computer.resized.connect(_fit_computer)
	_fit_computer()
	continue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_button.focus_mode = Control.FOCUS_NONE

## Called only once the driver and truck have finished leaving the map.
## This layer processes while paused; the gameplay world beneath it does not.
func show_round_over(round_number: int, bottles: int, earned: int, balance: int) -> void:
	round_won_sound.play()
	_balance = balance
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
	_disarm_confirm()
	_busy = false

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
	_build_choices()
	computer.modulate.a = 0.0
	computer.show()
	_fit_computer()
	_screen = &"computer"
	await _fade(computer, 1.0)
	_disarm_confirm()
	_busy = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_focus_cell(0, 0)

## Disable confirmation before emitting so double presses cannot skip two rounds.
func _request_next_round() -> void:
	if _busy or _screen != &"computer":
		return
	_busy = true
	next_round_requested.emit()

## Game calls this after all fresh round nodes have been added and connected.
## Gameplay stays paused until the fade has fully revealed the restored world.
func reveal_next_round() -> void:
	round_won_sound.stop()
	await _fade(overlay, 0.0)
	overlay.hide()
	computer.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _choice_root:
		_choice_root.queue_free()
		_choice_root = null
	_screen = &"hidden"
	_busy = false

## Accept mouse clicks, Enter/Space and either station action on a controller.
## Consume confirmation here so it cannot also operate a machine underneath.
func _input(event: InputEvent) -> void:
	if not overlay.visible:
		return
	if _screen == &"computer" and (event is InputEventMouse or _is_direction(event)):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if event.is_echo() or _busy or not _confirm_armed:
			return
		if _screen == &"summary":
			_show_computer()
		elif _screen == &"computer":
			var focused := _current_button()
			if focused and not focused.disabled:
				focused.pressed.emit()
	elif event is InputEventMouseButton or event.is_action("interact2") or event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()

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


func _build_choices() -> void:
	if _choice_root:
		_choice_root.queue_free()
	_choice_root = VBoxContainer.new()
	_choice_root.position = Vector2(77, 40)
	_choice_root.size = Vector2(998, 390)
	_choice_root.add_theme_constant_override("separation", 8)
	computer.get_node("Design").add_child(_choice_root)

	_choice_root.add_child(_label("CHOOSE AN UPGRADE   -   $%d" % _balance, 34, HEADER_COLOR))

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 20)
	_choice_root.add_child(row)

	_first_button = null
	_grid.clear()
	for modifier in Modifiers.roll_choices():
		row.add_child(_make_card(modifier))


func _make_card(modifier: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	card.add_theme_stylebox_override("panel", _card_style())

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	box.add_child(_label(modifier.title, 30, TITLE_COLOR))
	box.add_child(_label("+ " + modifier.buff, 20, BUFF_COLOR))
	box.add_child(_label("- " + modifier.debuff, 20, DEBUFF_COLOR))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var pick := _button("PICK")
	pick.pressed.connect(_choose.bind(modifier, false))
	box.add_child(pick)

	var clean := _button("NO DEBUFF  $%d" % modifier.cost)
	clean.disabled = _balance < modifier.cost
	if clean.disabled:
		clean.modulate = Color(1, 1, 1, 0.4)
	clean.pressed.connect(_choose.bind(modifier, true))
	box.add_child(clean)

	if _first_button == null:
		_first_button = pick
	for button in [pick, clean]:
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
	_grid.append([pick, clean])
	return card


func _choose(modifier: Dictionary, remove_debuff: bool) -> void:
	if _busy or _screen != &"computer":
		return
	if remove_debuff and _balance < modifier.cost:
		return
	modifier_chosen.emit(modifier, remove_debuff)
	_request_next_round()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String) -> Button:
	var button := MENU_BUTTON.instantiate() as Button
	button.text = text
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_FILL
	button.add_theme_font_size_override("font_size", 24)
	var normal := button.get_theme_stylebox("normal")
	var hover := button.get_theme_stylebox("hover")
	button.focus_entered.connect(button.add_theme_stylebox_override.bind("normal", hover))
	button.focus_exited.connect(button.add_theme_stylebox_override.bind("normal", normal))
	return button


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.065, 0.035, 0.92)
	style.border_color = Color(0.53, 0.37, 0.18, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	return style


func _process(_delta: float) -> void:
	if not _confirm_armed and Time.get_ticks_msec() >= _arm_at_msec and not _confirm_held():
		_confirm_armed = true
	if _screen != &"computer" or _busy or _grid.is_empty():
		return
	for action in DIRECTIONS:
		if Input.is_action_just_pressed(action) or Input.is_action_just_pressed("ui_" + action):
			var step: Vector2i = DIRECTIONS[action]
			_focus_cell(_col + step.x, _row + step.y)
			return


func _is_direction(event: InputEvent) -> bool:
	for action in DIRECTIONS:
		if event.is_action(action) or event.is_action("ui_" + action):
			return true
	return false


func _current_button() -> Button:
	if _grid.is_empty():
		return null
	return _grid[_col][_row]


func _focus_cell(col: int, row: int) -> void:
	if _grid.is_empty():
		return
	col = clampi(col, 0, _grid.size() - 1)
	row = clampi(row, 0, 1)
	var target: Button = _grid[col][row]
	if target.disabled:
		row = 0
		target = _grid[col][0]
	var previous := _current_button()
	if previous and previous != target:
		previous.focus_exited.emit()
		_set_selected(previous, false)
	_col = col
	_row = row
	target.focus_entered.emit()
	_set_selected(target, true)


func _set_selected(button: Button, selected: bool) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2.ONE * (1.08 if selected else 1.0)
	button.modulate = Color(1.3, 1.3, 1.15) if selected else Color.WHITE


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _disarm_confirm() -> void:
	_confirm_armed = false
	_arm_at_msec = Time.get_ticks_msec() + ARM_DELAY_MSEC


func _confirm_held() -> bool:
	for action in CONFIRM_ACTIONS:
		if Input.is_action_pressed(action):
			return true
	return false
