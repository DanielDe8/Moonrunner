extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scene_path := ""
	if owner != null:
		scene_path = owner.scene_file_path
	elif get_tree().current_scene != null:
		scene_path = get_tree().current_scene.scene_file_path

	if "konec" in scene_path.to_lower():
		self.text = "[font=res://Assets/Pixel12x10-v1.1.0.ttf][wave amp=20 freq=2]You win[/wave][/font]"
	else:
		self.text = "[font=res://Assets/Pixel12x10-v1.1.0.ttf][wave amp=20 freq=2]Moonrider[/wave][/font]"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
