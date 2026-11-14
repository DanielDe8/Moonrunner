class_name Collectable
extends Area2D
## Base script for mineable ores and collectables that disappear after a mining delay.

## Spawn weighting and cluster settings (used if placed by a spawner).
@export_range(0.0, 1.0, 0.001) var spawn_chance: float = 0.008
@export var min_cluster_size: int = 3
@export var max_cluster_size: int = 5
@export var min_distance: int = 5
@export var max_distance: int = -1
<<<<<<< HEAD
## Seconds to wait after the player touches this collectable before removing it.
@export var collect_delay: float = 1.0

var _collecting: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Starts the mining animation and removes the collectable after collect_delay.
func _on_body_entered(body: Node2D) -> void:
	if _collecting:
		return
	if body.is_in_group("Player") or body.name == "Player":
		_collecting = true
		if body.has_method("play_mining"):
			body.play_mining()
		await get_tree().create_timer(collect_delay).timeout
=======
@export var hp: float = 1.0   # seconds to wait before the ore is collected


func mine(delta: float) -> void:
	hp -= delta
	
	if hp <= 0.0:
>>>>>>> origin/master
		queue_free()
		
