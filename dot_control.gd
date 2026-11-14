extends Control

@export var player: Node2D          # drag your player here
@export var base: Node2D            # drag your base here
@export var margin: float = 8.0     # pixels from the screen edge
@export var hide_when_visible: bool = true
@export var compass_size: int = 16;

@onready var dot: Control = $Dot

func _ready() -> void:
	# Make sure this Control covers the screen and doesn't eat clicks
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.custom_minimum_size = Vector2(compass_size, compass_size)
	dot.size = Vector2(compass_size, compass_size)

func _process(_delta: float) -> void:
	if player == null or base == null:
		return

	var to_base: Vector2 = base.global_position - player.global_position
	if to_base.length() < 1.0:
		dot.visible = false
		return

	var dir: Vector2 = to_base.normalized()
	var area: Vector2 = get_viewport_rect().size

	# Half-size of the area the dot may travel in (inside the margin)
	var half: Vector2 = area / 2.0 - Vector2(margin, margin) - dot.size / 2.0
	if half.x <= 0.0 or half.y <= 0.0:
		return  # dot is too big for the screen/margin

	# Scale the direction until it touches the rectangle edge
	var tx: float = INF if is_zero_approx(dir.x) else half.x / absf(dir.x)
	var ty: float = INF if is_zero_approx(dir.y) else half.y / absf(dir.y)
	var t: float = minf(tx, ty)

	dot.position = area / 2.0 + dir * t - dot.size / 2.0

	# Hide the dot once the base is actually on screen (camera/zoom aware)
	if hide_when_visible:
		var base_screen: Vector2 = get_viewport().get_canvas_transform() * base.global_position
		var on_screen: bool = Rect2(Vector2.ZERO, area).grow(-margin).has_point(base_screen)
		dot.visible = not on_screen
	else:
		dot.visible = true
