extends TileMapLayer

@export var ore_scene: PackedScene = preload("res://Objects/collecteble_template.tscn")
@export var cluster_count: int = 25
@export var min_cluster_size: int = 3
@export var max_cluster_size: int = 7
@export var min_spawn_distance: int = 4

@onready var ground_layer: TileMapLayer = $"../TileMapLayer"


func _ready() -> void:
	generate_ore_clusters()


func generate_ore_clusters() -> void:
	var floor_cells: Array[Vector2i] = ground_layer.get_used_cells()
	if floor_cells.is_empty():
		return

	var floor_set: Dictionary = {}
	for cell in floor_cells:
		floor_set[cell] = true

	var occupied: Dictionary = {}
	var offsets: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1),
		Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]

	for i in range(cluster_count):
		var center: Vector2i = floor_cells.pick_random()
		if center.length() < min_spawn_distance:
			continue

		var count: int = randi_range(min_cluster_size, max_cluster_size)
		var current: Vector2i = center

		for j in range(count):
			var target: Vector2i = current + offsets.pick_random()
			if floor_set.has(target) and not occupied.has(target):
				occupied[target] = true
				var ore = ore_scene.instantiate()
				ore.position = ground_layer.map_to_local(target)
				add_child(ore)
				current = target
