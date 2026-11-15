class_name Collectable
extends Area2D

@export_range(0.0, 1.0, 0.001) var spawn_chance: float = 0.008
@export var min_cluster_size: int = 3
@export var max_cluster_size: int = 5
@export var min_distance: int = 5
@export var max_distance: int = -1
@export var hp: float = 1.0
@export var stat_name: String = "red_ore_count"
@export var require_mining: bool = true

@onready var player: Node = get_tree().get_first_node_in_group("Player")


func _ready() -> void:
	if not require_mining:
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not require_mining and (body.is_in_group("Player") or body.name == "player" or body.name == "Player"):
		_collect()


func mine(delta: float) -> void:
	if not require_mining:
		return
	hp -= delta

	if hp <= 0.0:
		_collect()


func _collect() -> void:
	if player != null and stat_name != "" and stat_name in player:
		player.set(stat_name, player.get(stat_name) + 1)
	queue_free()
		
