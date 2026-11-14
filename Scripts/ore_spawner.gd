extends TileMapLayer

const DIRS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]

@export var map_seed: int = 0
@export var view_radius: int = 22
@export var max_view_radius: int = 60

@onready var ground_layer: TileMapLayer = $"../TileMapLayer"
@onready var player: CharacterBody2D = $"../player"

var active_seed: int = 0
var base_cell := Vector2i.ZERO
var spawn_configs: Array[Dictionary] = []
var generated_cells: Dictionary = {}
var occupied_cells: Dictionary = {}
var pending_spawns: Dictionary = {}
var last_player_cell := Vector2i(999999, 999999)
var last_active_radius: int = 0


func _ready() -> void:
	load_spawn_configs()
	ground_layer.clear()
	clear()
	update_map()


func _physics_process(_delta: float) -> void:
	update_map()


func load_spawn_configs() -> void:
	spawn_configs.clear()
	var main_node := get_parent()
	if main_node == null or not ("spawnable_objects" in main_node):
		return

	for scene in main_node.spawnable_objects:
		if scene == null:
			continue
		var sample: Node = scene.instantiate()
		var config := {
			"scene": scene,
			"spawn_chance": float(sample.get("spawn_chance")) if "spawn_chance" in sample else 0.008,
			"min_size": int(sample.get("min_cluster_size")) if "min_cluster_size" in sample else 3,
			"max_size": int(sample.get("max_cluster_size")) if "max_cluster_size" in sample else 5,
			"min_dist": int(sample.get("min_distance")) if "min_distance" in sample else 5,
			"max_dist": int(sample.get("max_distance")) if "max_distance" in sample else -1
		}
		sample.free()
		spawn_configs.append(config)


func update_map() -> void:
	if player == null:
		return
	var current_cell: Vector2i = ground_layer.local_to_map(player.global_position)
	var active_radius: int = get_active_view_radius()
	if current_cell != last_player_cell or active_radius > last_active_radius:
		last_player_cell = current_cell
		last_active_radius = active_radius
		generate_circle(current_cell, active_radius)


func get_active_view_radius() -> int:
	if player != null and player.has_node("Camera2D"):
		var zoom_val: float = max(player.get_node("Camera2D").zoom.x, 0.5)
		var zoom_radius: int = int(ceil(52.0 / zoom_val))
		return clampi(max(view_radius, zoom_radius), view_radius, max(view_radius, max_view_radius))
	return view_radius


func generate_circle(center: Vector2i, radius: int) -> void:
	var r_sq: int = radius * radius
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var dx: int = x - center.x
			var dy: int = y - center.y
			if dx * dx + dy * dy <= r_sq:
				var cell := Vector2i(x, y)
				if not generated_cells.has(cell):
					generate_tile(cell)


func generate_tile(cell: Vector2i) -> void:
	generated_cells[cell] = true
	ground_layer.set_cell(cell, 0, Vector2i.ZERO, 2)

	if pending_spawns.has(cell):
		spawn_at(cell, pending_spawns[cell])
		pending_spawns.erase(cell)
		return

	if occupied_cells.has(cell) or spawn_configs.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = hash([active_seed, cell.x, cell.y])

	var order := spawn_configs.duplicate()
	shuffle_array(order, rng)

	for config in order:
		if can_place_at(cell, config, {}) and rng.randf() < config.spawn_chance:
			spawn_cluster(cell, config, rng)
			break


func can_place_at(cell: Vector2i, config: Dictionary, own_cluster: Dictionary) -> bool:
	if occupied_cells.has(cell):
		return false
	for d in DIRS:
		var neighbor: Vector2i = cell + d
		if occupied_cells.has(neighbor) and not own_cluster.has(neighbor):
			return false
	var dist: float = Vector2(cell - base_cell).length()
	if dist < float(config.min_dist):
		return false
	if config.max_dist >= 0 and dist > float(config.max_dist):
		return false
	return true


func spawn_cluster(center: Vector2i, config: Dictionary, rng: RandomNumberGenerator) -> void:
	var min_size: int = max(1, config.min_size)
	var target: int = rng.randi_range(min_size, max(min_size, config.max_size))
	var queue: Array[Vector2i] = [center]
	var visited: Dictionary = {center: true}
	var own_cluster: Dictionary = {}

	while own_cluster.size() < target and not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if not can_place_at(cell, config, own_cluster):
			continue

		occupied_cells[cell] = true
		own_cluster[cell] = true
		if generated_cells.has(cell):
			spawn_at(cell, config.scene)
		else:
			pending_spawns[cell] = config.scene

		var neighbors := DIRS.duplicate()
		shuffle_array(neighbors, rng)
		for d in neighbors:
			var next_cell: Vector2i = cell + d
			if not visited.has(next_cell):
				visited[next_cell] = true
				queue.append(next_cell)


func spawn_at(cell: Vector2i, scene: PackedScene) -> void:
	var obj := scene.instantiate()
	obj.position = ground_layer.map_to_local(cell)
	add_child(obj)


func shuffle_array(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
