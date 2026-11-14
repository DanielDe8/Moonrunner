extends Control
## Keeps a HUD indicator dot clamped to the screen edge pointing toward the base.

@export var player: Node2D          # Player node used as the origin
@export var base: Node2D            # Base node the dot points toward
@export var margin: float = 8.0     # Pixels of padding from the Control's edges
@export var hide_when_visible: bool = true

@onready var dot: Control = $Dot


func _process(_delta: float) -> void:
	if player == null or base == null:
		return

	var to_base: Vector2 = base.global_position - player.global_position
	if to_base.length() < 1.0:
		return

	var dir: Vector2 = to_base.normalized()

	# Half-size of the rectangle the dot center can move within.
	var half: Vector2 = size / 2.0 - Vector2(margin, margin) - dot.size / 2.0

	# Project the direction vector onto the nearest horizontal or vertical edge.
	var t: float = minf(half.x / absf(dir.x), half.y / absf(dir.y))
	dot.position = size / 2.0 + dir * t - dot.size / 2.0

	# Hide the indicator while the base is already within the screen bounds.
	if hide_when_visible:
		var on_screen: bool = absf(to_base.x) < half.x and absf(to_base.y) < half.y
		dot.visible = not on_screen
