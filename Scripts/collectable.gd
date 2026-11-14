class_name Collectable
extends Area2D

@export_range(0.0, 1.0, 0.001) var spawn_chance: float = 0.008
@export var min_cluster_size: int = 3
@export var max_cluster_size: int = 5
@export var min_distance: int = 5
@export var max_distance: int = -1
@export var collect_delay: float = 1.0   # seconds to wait before the ore is collected

var _collecting: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _collecting:
		return
	if body.is_in_group("Player") or body.name == "Player":
		_collecting = true
		if body.has_method("play_mining"):
			body.play_mining()
		await get_tree().create_timer(collect_delay).timeout
		queue_free()
