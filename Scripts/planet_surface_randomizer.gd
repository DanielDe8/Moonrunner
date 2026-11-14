extends Node2D


func _ready() -> void:
	get_child(4).hide()
	var sprite = get_child(randi_range(0, 3))
	sprite.show()
	sprite.rotation_degrees = randi_range(0, 3) * 90
