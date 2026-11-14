extends Node2D

@onready var ore_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Your ore tracking variable
var ores_mined: int = 0:
	set(value):
		ores_mined = value
		_update_ore_visual()

func _ready() -> void:
	# Stop the animation from automatically playing/looping
	ore_sprite.stop()
	_update_ore_visual()

func _update_ore_visual() -> void:
	# Clamp the frame index so it doesn't exceed your available animation frames
	# Assuming you have frames 0 through 4 (5 total states)
	var target_frame = clamp(ores_mined, 0, ore_sprite.sprite_frames.get_frame_count("default") - 1)
	
	# Set the specific frame directly
	ore_sprite.frame = target_frame
