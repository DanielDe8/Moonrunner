extends Node2D

@export var max_ores = 40

@onready var ore_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Stop the animation from automatically playing/looping
	ore_sprite.stop()
	update_ore_visual(0.0)

func update_ore_visual(ores: int) -> void:
	# Clamp the frame index so it doesn't exceed your available animation frames
	# Assuming you have frames 0 through 4 (5 total states)
	var target_frame: int = (float(ores) / float(max_ores)) * (ore_sprite.sprite_frames.get_frame_count("default") - 1)
	
	# Set the specific frame directly
	ore_sprite.frame = target_frame
