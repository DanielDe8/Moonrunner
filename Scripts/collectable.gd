class_name Collectable
extends Area2D
## Base script for mineable ores and collectables that disappear after a mining delay.

## Spawn weighting and cluster settings (used if placed by a spawner).
@export_range(0.0, 1.0, 0.001) var spawn_chance: float = 0.008
@export var min_cluster_size: int = 3
@export var max_cluster_size: int = 5
@export var min_distance: int = 5
@export var max_distance: int = -1
## Seconds of mining required before this ore is collected.
@export var hp: float = 1.0


## Reduces hp while mined and frees the collectable once depleted.
func mine(delta: float) -> void:
	hp -= delta

	if hp <= 0.0:
		queue_free()
		
