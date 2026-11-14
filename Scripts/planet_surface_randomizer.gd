extends Node2D
## Picks one of the 4 surface tile variants at random and rotates it in 90-degree steps.


func _ready() -> void:
	# Hide the placeholder "random" preview sprite (child index 4).
	get_child(4).hide()
	# Show one of the first 4 surface sprites and give it a random 90-degree orientation.
	var sprite = get_child(randi_range(0, 3))
	sprite.show()
	sprite.rotation_degrees = randi_range(0, 3) * 90
