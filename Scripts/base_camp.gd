extends Node2D

var player_in_camp: bool = false


func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "player" or body.name == "Player":
		player_in_camp = true
		if "near_camp" in body:
			body.near_camp = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "player" or body.name == "Player":
		player_in_camp = false
		if "near_camp" in body:
			body.near_camp = false
