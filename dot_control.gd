extends Control

@export var player: Node2D          # drag your player here
@export var base: Node2D            # drag your base here
@export var margin: float = 8.0     # pixels from the screen edge
@export var hide_when_visible: bool = true

@onready var dot: Control = $Dot

func _process(_delta: float) -> void:
	if player == null or base == null:
		return

	var to_base: Vector2 = base.global_position - player.global_position
	if to_base.length() < 1.0:
		return

	var dir: Vector2 = to_base.normalized()

	# Half-size of the area the dot may travel in (inside the margin)
	var half: Vector2 = size / 2.0 - Vector2(margin, margin) - dot.size / 2.0

	# Scale the direction until it touches the rectangle edge
	var t: float = minf(half.x / absf(dir.x), half.y / absf(dir.y))

	dot.position = size / 2.0 + dir * t - dot.size / 2.0

	# Optional: hide the dot once the base is on screen
	if hide_when_visible:
		var on_screen: bool = absf(to_base.x) < half.x and absf(to_base.y) < half.y
		dot.visible = not on_screen
