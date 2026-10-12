extends Camera3D

@export var framed_width: float = 46.0
@export var framed_height: float = 27.211

func _ready() -> void:
	get_viewport().size_changed.connect(_fit_frame)
	_fit_frame()

func _fit_frame() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	# Camera size measures the locked axis, not always the vertical span.
	var aspect := viewport_size.x / viewport_size.y
	if keep_aspect == KEEP_WIDTH:
		size = maxf(framed_width, framed_height * aspect)
	else:
		size = maxf(framed_height, framed_width / aspect)
