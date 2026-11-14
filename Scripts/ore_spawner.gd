extends TileMapLayer

@export var map_seed: int = 0
@export var view_radius: int = 22
@export var max_view_radius: int = 60
@export var infinite_follow_player: bool = true
@export var ore_frequency: float = 0.05
@export var ore_size_threshold: float = 0.45
@export var starting_area_radius: int = 4
@export var spawn_starter_patch: bool = true

@onready var ground_layer: TileMapLayer = $"../TileMapLayer"
@onready var player: CharacterBody2D = $"../player"

var generated_cells: Dictionary = {}
var ore_noise := FastNoiseLite.new()
var edge_noise := FastNoiseLite.new()
var type_noise := FastNoiseLite.new()
var starter_patch_center := Vector2i(6, -2)
var last_player_cell := Vector2i(999999, 999999)
var last_active_radius: int = 0


func _ready() -> void:
	setup_noise()
	ground_layer.clear()
	clear()
	generate_circle_area(Vector2i.ZERO, view_radius)
	if infinite_follow_player:
		update_map_around_player()
	else:
		create_circular_boundary(view_radius)


func _physics_process(_delta: float) -> void:
	if infinite_follow_player and player != null:
		var current_cell: Vector2i = ground_layer.local_to_map(player.global_position)
		var active_radius: int = get_active_view_radius()
		if current_cell != last_player_cell or active_radius > last_active_radius:
			last_player_cell = current_cell
			last_active_radius = active_radius
			generate_circle_area(current_cell, active_radius)


func get_active_view_radius() -> int:
	if player != null and player.has_node("Camera2D"):
		var cam: Camera2D = player.get_node("Camera2D")
		var zoom_val: float = max(cam.zoom.x, 0.5)
		var zoom_needed_radius: int = int(ceil(52.0 / zoom_val))
		return clampi(max(view_radius, zoom_needed_radius), view_radius, max(view_radius, max_view_radius))
	return view_radius


func setup_noise() -> void:
	var active_seed: int = map_seed if map_seed != 0 else randi()
	ore_noise.seed = active_seed
	ore_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ore_noise.frequency = ore_frequency
	ore_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	ore_noise.fractal_octaves = 2

	edge_noise.seed = active_seed + 1337
	edge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	edge_noise.frequency = 0.22

	type_noise.seed = active_seed + 4242
	type_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	type_noise.frequency = 0.018

	var angle: float = randf() * TAU
	var dist: float = float(starting_area_radius + 3)
	starter_patch_center = Vector2i(int(round(cos(angle) * dist)), int(round(sin(angle) * dist)))


func get_spawnable_objects() -> Array[PackedScene]:
	var main_node := get_parent()
	if main_node != null and "spawnable_objects" in main_node:
		var list: Array[PackedScene] = main_node.spawnable_objects
		if not list.is_empty():
			return list
	return []


func update_map_around_player() -> void:
	var center: Vector2i = Vector2i.ZERO
	if player != null:
		center = ground_layer.local_to_map(player.global_position)
	var active_radius: int = get_active_view_radius()
	last_active_radius = active_radius
	generate_circle_area(center, active_radius)


func generate_circle_area(center: Vector2i, radius: int) -> void:
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
	var obj_index: int = get_spawn_object_index(cell)
	if obj_index >= 0:
		var objects := get_spawnable_objects()
		if obj_index < objects.size() and objects[obj_index] != null:
			var obj := objects[obj_index].instantiate()
			obj.position = ground_layer.map_to_local(cell)
			add_child(obj)


func get_spawn_object_index(cell: Vector2i) -> int:
	var objects := get_spawnable_objects()
	if objects.is_empty():
		return -1

	var dist_from_origin: float = Vector2(cell).length()
	if dist_from_origin < float(starting_area_radius):
		return -1

	var jitter: float = edge_noise.get_noise_2d(float(cell.x), float(cell.y)) * 0.12

	if spawn_starter_patch:
		var starter_dist: float = Vector2(cell - starter_patch_center).length()
		if starter_dist <= 2.2 + jitter * 3.0:
			return 0

	var base_val: float = ore_noise.get_noise_2d(float(cell.x), float(cell.y))
	if (base_val + jitter) <= ore_size_threshold:
		return -1

	if objects.size() == 1:
		return 0

	var norm: float = clampf((type_noise.get_noise_2d(float(cell.x), float(cell.y)) + 0.6) / 1.2, 0.0, 0.9999)
	return int(floor(norm * float(objects.size())))


func create_circular_boundary(radius: int) -> void:
	var tile_size: float = float(ground_layer.tile_set.tile_size.x)
	var pixel_radius: float = float(radius) * tile_size
	var wall := StaticBody2D.new()
	wall.name = "MapBoundary"
	var segments: int = 64
	for i in range(segments):
		var angle1: float = TAU * float(i) / float(segments)
		var angle2: float = TAU * float(i + 1) / float(segments)
		var p1 := Vector2(cos(angle1), sin(angle1)) * pixel_radius
		var p2 := Vector2(cos(angle2), sin(angle2)) * pixel_radius
		var shape := SegmentShape2D.new()
		shape.a = p1
		shape.b = p2
		var col := CollisionShape2D.new()
		col.shape = shape
		wall.add_child(col)
	add_child(wall)
