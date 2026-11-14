extends Node2D
## Base camp node that tracks whether the player is inside its safe/charging zone.

## True while the player is overlapping the camp's Area2D.
var player_in_camp: bool = false


func _ready() -> void:
	# Listen for bodies entering and leaving the camp's detection zone.
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)


## Marks the player as inside the camp when they enter the Area2D.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "player" or body.name == "Player":
		player_in_camp = true
		if "near_camp" in body:
			body.near_camp = true


## Clears the camp flag when the player leaves the Area2D.
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "player" or body.name == "Player":
		player_in_camp = false
		if "near_camp" in body:
			body.near_camp = false
