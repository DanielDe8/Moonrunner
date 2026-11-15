extends Node2D

func _ready() -> void:
	get_node("Control/VBoxContainer/GoButton").pressed.connect(_on_go_pressed)
	#get_node("CenterContainer/VBoxContainer/CreditsButton").pressed.connect(_on_credits_pressed)

func _on_go_pressed() -> void:
	print("GO button pressed")
	get_tree().change_scene_to_file.call_deferred("res://Objects/Main.tscn")

#func _on_credits_pressed() -> void:
	#print("Credits button pressed")
	#get_tree().change_scene_to_file.call_deferred("res://credits.tscn")
