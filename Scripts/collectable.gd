class_name Collectable
extends Area2D

@export_range(0.0, 1.0, 0.001) var spawn_chance: float = 0.008
@export var min_cluster_size: int = 3
@export var max_cluster_size: int = 5
@export var min_distance: int = 5
@export var max_distance: int = -1
@export var hp: float = 1.0   # seconds to wait before the ore is collected


func mine(delta: float) -> void:
	hp -= delta
	
	if hp <= 0.0:
		queue_free()
		
