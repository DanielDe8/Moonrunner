extends Control
## Keeps a HUD indicator dot clamped to the screen edge pointing toward the base.

@export var player: Node2D          # Player node (optional)
@export var base: Node2D            # Base node the dot points toward
@export var margin: float = 16.0    # Pixels of padding from the screen edges
@export var hide_when_visible: bool = true

@onready var dot: Control = $Dot


func _process(_delta: float) -> void:
	if base == null or dot == null:
		return

	# Use the actual viewport size and canvas transform so camera zoom & smoothing are handled accurately.
	var screen_size: Vector2 = get_viewport_rect().size
	var screen_center: Vector2 = screen_size / 2.0
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * base.global_position
	var to_base_screen: Vector2 = screen_pos - screen_center

	# Hide the dot when the base is already visible inside the screen bounds.
	if hide_when_visible:
		var visible_rect := Rect2(Vector2.ZERO, screen_size)
		if visible_rect.has_point(screen_pos):
			dot.visible = false
			return
		dot.visible = true

	if to_base_screen.length() < 1.0:
		return

	var dir: Vector2 = to_base_screen.normalized()

	# Half-size of the rectangle the dot center can travel within.
	var half: Vector2 = screen_center - Vector2(margin, margin) - dot.size / 2.0
	if half.x <= 0.0 or half.y <= 0.0:
		return

	# Project the direction vector onto the nearest horizontal or vertical edge (guarded against / 0).
	var tx: float = half.x / maxf(absf(dir.x), 0.0001)
	var ty: float = half.y / maxf(absf(dir.y), 0.0001)
	var t: float = minf(tx, ty)

	dot.position = screen_center + dir * t - dot.size / 2.0
