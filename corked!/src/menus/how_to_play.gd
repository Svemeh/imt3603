extends Control
## Shared guide: standalone from the menu, or a paused overlay over the game.
## The lobby's PlayerManager slots survive this scene unchanged.

const UI := "res://assets/ui/"
const ART := UI + "tutorial/"
const INK := Color("42240e")
const CREAM := Color("fff1d0")
const OLIVE := Color("656627")
## Each entry contains: heading, main instruction, and the green helper text.
## Use action names here; the shared legend explains each device’s buttons.
const STEPS := [
	["Harvest your grapes", "With empty hands, walk to a vine. Press Use to harvest, then carry the grapes to the stomping station.", "Use: Harvest • Pick up / Place: Carry"],
	["Stomp them into juice", "Pick up an empty barrel and Place it at the stomping station. Place grapes in the stomping station, then tap Use repeatedly until the barrel is full of juice.", "Place: Barrel / Grapes • Use: Stomp"],
	["Keep fermentation flowing", "Use to pour juice at the tank inlet. Place an empty barrel at the output. Time Use presses in the target zone to keep pressure green.", "Green pressure = wine flowing"],
	["Bottle a full crate", "Place a wine barrel at the bottling line. Press Use for each bottle. A full crate holds 4 bottles; Pick up the crate.", "Machine broken? Grab a hammer and repair it."],
	["Load up, then send it!", "Place full crates in the truck’s loading zone until you meet the current round’s quota. Then press Use beside the driver to send the delivery.", "Sending the truck short ends the run."]
]

## The game owns pausing and the timer. This UI only asks it to continue or leave.
signal begin_requested
signal back_requested

## Set before adding this scene to the tree. False = main-menu reference;
## true = popup over the paused game, including the goal and start button.
var in_game := false

var canvas: Control
var legend: Control
var begin_button: Button
var back_button: Button
var _starting := false
var _font: Font = preload("res://assets/ui/PatrickHand-Regular.ttf")

## Build the shared guide and focus the button appropriate to the way it was opened.
func _ready() -> void:
	if not in_game:
		MenuMusic.play_menu_music()
	var theme_style := Theme.new()
	theme_style.default_font = _font
	theme_style.default_font_size = 30
	theme = theme_style
	if in_game:
		var dim := ColorRect.new()
		# Draw before the guide so only the map behind it is darkened.
		dim.name = "MapDimmer"
		dim.color = Color(0.0, 0.0, 0.0, 0.68)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
	canvas = Control.new()
	add_child(canvas)
	canvas.size = Vector2(1920, 1080)
	_build_menu()
	get_viewport().size_changed.connect(_fit_viewport)
	_fit_viewport()
	if in_game:
		begin_button.grab_focus()
	else:
		back_button.grab_focus()

## Lay out once at 1920×1080, then scale uniformly to fit the actual window.
## The popup is slightly smaller so the real map remains visible around its edges.
func _fit_viewport() -> void:
	var viewport := get_viewport_rect().size
	var factor := minf(viewport.x / 1920.0, viewport.y / 1080.0)
	if in_game:
		factor *= 0.88
	canvas.scale = Vector2.ONE * factor
	canvas.position = (viewport - canvas.size * factor) / 2.0

## Create decorative artwork or a gameplay crop. Cover fills a frame without
## stretching the image; clipping prevents the crop from spilling over the frame.
func _texture(path: String, rect: Rect2, parent: Node, cover := false) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture = load(path)
	node.position = rect.position
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.size = rect.size
	node.clip_contents = true
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	# Reapply after Godot resolves texture minimum sizes on entering the tree.
	node.set_deferred("size", rect.size)
	return node

## Create wrapped tutorial text. Light lettering gets a dark outline for contrast.
func _label(copy: String, rect: Rect2, parent: Node, font_size := 32, color := INK) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = copy
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if color == CREAM:
		label.add_theme_color_override("font_outline_color", Color("42240e"))
		label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	# Parent fonts can change the minimum size; set the intended width after layout.
	label.set_deferred("size", rect.size)
	return label

## Reuse the same normal, hover, and pressed artwork as the other game menus.
func _wood_button(copy: String, rect: Rect2, callback: Callable) -> Button:
	var button: Button = load(UI + "menu_button.tscn").instantiate()
	canvas.add_child(button)
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.position = rect.position
	button.size = rect.size
	button.text = copy
	button.add_theme_font_size_override("font_size", 34)
	# Keep normal, hover and pressed textures from the shared menu button.
	# Keyboard/controller focus must not force the hover appearance.
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(callback)
	return button

## Build the fixed, single-screen layout. All coordinates use the 1920×1080 canvas.
## Most content is shared; only the in-game version includes the round-start footer.
func _build_menu() -> void:
	if not in_game:
		_texture(UI + "vineyard_background.png", Rect2(0, 0, 1920, 1080), canvas, true)
	_texture(UI + "settings_panel.png", Rect2(35, 100, 1850, 930), canvas).stretch_mode = TextureRect.STRETCH_SCALE
	_texture(UI + "corked_logo.png", Rect2(85, 12, 350, 135), canvas)
	_texture(UI + "player_plaque.png", Rect2(630, 0, 660, 148), canvas)
	var title := _label("HOW TO PLAY", Rect2(710, 39, 500, 66), canvas, 58, CREAM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_button = _wood_button("BACK", Rect2(1560, 26, 270, 90), _back_to_lobby)

	var paper := Panel.new()
	paper.position = Vector2(120, 168)
	paper.size = Vector2(1680, 888 if in_game else 788)
	var parchment := StyleBoxTexture.new()
	parchment.texture = load(ART + "parchment.png")
	parchment.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	parchment.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	# Bleed the parchment beneath the wood so fractional viewport scaling
	# cannot expose the background between independently drawn edges.
	parchment.expand_margin_left = 5.0
	parchment.expand_margin_right = 5.0
	parchment.expand_margin_top = 3.0
	parchment.expand_margin_bottom = 3.0
	paper.add_theme_stylebox_override("panel", parchment)
	canvas.add_child(paper)
	# Three steps in the left column, two in the right; the legend sits below both.
	for i in 3:
		_add_step(paper, i, Vector2(27, 24 + i * 188), 180, 550)
	_add_step(paper, 3, Vector2(878, 40), 210, 510)
	_add_step(paper, 4, Vector2(878, 323), 210, 510)
	var divider := ColorRect.new()
	divider.position = Vector2(844, 26)
	divider.size = Vector2(2, 561)
	divider.color = Color("c5a16b")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(divider)
	_add_legend(paper, 603)
	_add_paper_border()
	if in_game:
		var footer_rule := ColorRect.new()
		footer_rule.position = Vector2(42, 780)
		footer_rule.size = Vector2(1596, 2)
		footer_rule.color = Color("c5a16b")
		footer_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paper.add_child(footer_rule)
		_label("FIRST ROUND GOAL • Deliver 8 bottles (2 full crates) within 6 minutes.", Rect2(42, 790, 1180, 42), paper, 29, INK)
		_label("Ready to start? Choose Let’s Make Wine!", Rect2(42, 838, 1150, 40), paper, 27, OLIVE)
		begin_button = _wood_button("LET’S MAKE WINE!", Rect2(1390, 954, 380, 90), _begin_round)

## Draw a resizable border and two inset trim lines around the parchment.
func _add_paper_border() -> void:
	# Native, resizable UI geometry: no enlarged screenshot fragment or baked text.
	var border := Panel.new()
	border.name = "ParchmentBorder"
	border.position = Vector2(99, 157)
	border.size = Vector2(1722, 910 if in_game else 810)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wood := StyleBoxFlat.new()
	wood.draw_center = false
	wood.border_color = Color("743e1c")
	wood.set_border_width_all(19)
	wood.set_corner_radius_all(16)
	wood.shadow_color = Color(0.12, 0.06, 0.02, 0.65)
	wood.shadow_size = 5
	border.add_theme_stylebox_override("panel", wood)
	canvas.add_child(border)
	for inset in [2, 16]:
		var trim := Panel.new()
		trim.position = Vector2.ONE * inset
		trim.size = border.size - Vector2.ONE * inset * 2
		trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bevel := StyleBoxFlat.new()
		bevel.draw_center = false
		bevel.border_color = Color("d6a058") if inset == 2 else Color("bd8039")
		bevel.set_border_width_all(2)
		bevel.set_corner_radius_all(13 if inset == 2 else 3)
		trim.add_theme_stylebox_override("panel", bevel)
		border.add_child(trim)

## Build one numbered screenshot-and-text row. Index is zero-based.
## The bottling crop uses a shorter frame to exclude the vineyard above the room.
func _add_step(parent: Control, index: int, origin: Vector2, image_size: int, text_width: int) -> void:
	var row := Control.new()
	row.name = "Step%d" % (index + 1)
	row.position = origin
	row.size = Vector2(image_size + 27 + text_width, image_size)
	parent.add_child(row)
	var image_height := 180 if index == 3 else image_size
	_texture(ART + "step_%d.png" % (index + 1), Rect2(13, 14, image_size - 29, image_height - 33), row, true)
	var frame := NinePatchRect.new()
	frame.texture = load(ART + "screenshot_frame.png")
	frame.size = Vector2(image_size, image_height)
	frame.patch_margin_left = 13
	frame.patch_margin_top = 14
	frame.patch_margin_right = 16
	frame.patch_margin_bottom = 19
	frame.draw_center = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)
	var badge := _label(str(index + 1), Rect2(-14, -7, 43, 47), row, 34, CREAM)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("754016")
	badge_style.border_color = Color("d5a355")
	badge_style.set_border_width_all(3)
	badge_style.set_corner_radius_all(20)
	badge.add_theme_stylebox_override("normal", badge_style)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var text_x := image_size + 27
	_label(STEPS[index][0], Rect2(text_x, 0, text_width, 43), row, 33)
	var body := _label(STEPS[index][1], Rect2(text_x, 46, text_width, 111), row, 25)
	var hint := _label(STEPS[index][2], Rect2(text_x, 160, text_width, 42), row, 23, OLIVE)
	if index == 0:
		_position_harvest_hint.call_deferred(body, hint)

## Place the harvesting helper immediately after the paragraph’s rendered lines.
func _position_harvest_hint(body: Label, hint: Label) -> void:
	# Measure the wrapped text after layout, rather than reserving a full row.
	hint.position.y = body.position.y + body.get_line_count() * body.get_line_height() + 8


## Build the action/device table once so individual steps do not repeat button names.
## Rows are header, Use, Pick up / Place, Run, Move; columns are action and devices.
func _add_legend(parent: Control, y: int) -> void:
	legend = Control.new()
	legend.name = "SharedControls"
	legend.position = Vector2(42, y)
	legend.size = Vector2(1596, 172)
	parent.add_child(legend)
	var rule := ColorRect.new()
	rule.size = Vector2(1596, 2)
	rule.color = Color("c5a16b")
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend.add_child(rule)
	var columns := [0, 540, 900, 1260]
	var rows := [
		["SHARED CONTROLS", "KEYBOARD", "PLAYSTATION", "XBOX"],
		["Use", "J", "Square", "X"],
		["Pick up / Place", "K", "Cross", "A"],
		["Run", "Shift", "L1", "LB"],
		["Move", "WASD / arrows", "Left stick", "Left stick"]
	]
	for row in rows.size():
		for col in 4:
			var x: int = columns[col]
			# The row pitch leaves a gap around 26-pixel icons and keycaps.
			var top := 7 if row == 0 else 40 + (row - 1) * 33
			if row == 0 or col == 0:
				_label(rows[row][col], Rect2(x, top, 520 if col == 0 else 330, 32), legend, 27, OLIVE if row == 0 else INK)
			elif col == 1:
				if row < 4:
					_legend_key(rows[row][col], Vector2(x, top), 76 if row == 3 else 32)
				else:
					for i in 4:
						_legend_key(["W", "A", "S", "D"][i], Vector2(x + i * 32, top), 29)
					_label("/", Rect2(x + 133, top, 18, 30), legend, 24)
					for i in 4:
						_legend_key(["↑", "←", "↓", "→"][i], Vector2(x + 156 + i * 32, top), 29)
			elif row in [1, 2]:
				var symbol: String
				if col == 2:
					symbol = "ps_square.svg" if row == 1 else "ps_cross.svg"
				else:
					symbol = "xbox_x.svg" if row == 1 else "xbox_a.svg"
				_texture(ART + symbol, Rect2(x, top + 2, 26, 26), legend)
			elif row == 3:
				_legend_key(rows[row][col], Vector2(x, top), 60)
			else:
				_texture(ART + "left_stick.svg", Rect2(x, top + 2, 26, 26), legend)
				_label("Left stick", Rect2(x + 37, top, 230, 30), legend, 25)

## Draw a keyboard keycap or controller shoulder button using the same visual style.
func _legend_key(copy: String, at: Vector2, width: int) -> void:
	var key := _label(copy, Rect2(at, Vector2(width, 26)), legend, 21, CREAM)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key.add_theme_constant_override("outline_size", 0)
	var cap := StyleBoxFlat.new()
	cap.bg_color = Color("302a28")
	cap.border_color = Color("b88a48")
	cap.set_border_width_all(2)
	cap.set_corner_radius_all(5)
	key.add_theme_stylebox_override("normal", cap)
	# Keep padding explicit so the label minimum cannot grow past its row.
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		cap.set_content_margin(side, 0.0)

## In the popup, ignore controllers that did not join the lobby.
## The standalone main-menu guide accepts any controller so it can be read before joining.
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if in_game and not PlayerManager.slots.has(event.device):
			get_viewport().set_input_as_handled()

## Let normal GUI button navigation run first, then handle Escape/controller Back.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("ui_cancel"):
		_back_to_lobby()
		get_viewport().set_input_as_handled()

## The destination depends on context: signal the game to leave its paused popup,
## or return directly to the main menu from the standalone reference screen.
func _back_to_lobby() -> void:
	if _starting:
		return
	if in_game:
		back_requested.emit()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

## Notify the game instead of loading a fresh scene, preserving the spawned players.
## The guard prevents repeated confirm events from starting the timer twice.
func _begin_round() -> void:
	if not in_game:
		_back_to_lobby()
		return
	if _starting:
		return
	_starting = true
	begin_requested.emit()
