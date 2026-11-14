extends TileMapLayer

const DIRS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]
const IMAGE_EXTENSIONS: Array[String] = ["png", "webp", "jpg", "jpeg", "svg"]

@export var map_seed: int = 0
@export var view_radius: int = 22
@export var max_view_radius: int = 60

@export_group("Rocks")
@export var rock_prefix: String = "rock"
@export var rock_folder: String = "res://Assets"    # scanned recursively
@export_range(0.0, 1.0, 0.001) var rock_spawn_chance: float = 0.02
@export var rock_min_distance: int = 6    # keep rocks away from the camp
@export var rock_max_distance: int = -1    # -1 = no limit

@onready var ground_layer: TileMapLayer = $"../TileMapLayer"
@onready var player: CharacterBody2D = $"../player"

var active_seed: int = 0
var base_cell := Vector2i.ZERO
var spawn_configs: Array[Dictionary] = []
var rock_tiles: Array[Dictionary] = []
var rock_textures: Array[Texture2D] = []
var generated_cells: Dictionary = {}
var occupied_cells: Dictionary = {}
var pending_spawns: Dictionary = {}
var last_player_cell := Vector2i(999999, 999999)
var last_active_radius: int = 0


func _ready() -> void:
	# Wait one frame to ensure the parent node and its exports are fully ready
	await get_tree().process_frame
	
	# Set base_cell to the player's starting position so distance checks work
	if player != null:
		base_cell = ground_layer.local_to_map(player.global_position)
	
	load_spawn_configs()
	discover_rock_tiles()
	discover_rock_textures()
	ground_layer.clear()
	clear()
	update_map()


func _physics_process(_delta: float) -> void:
	update_map()


func load_spawn_configs() -> void:
	spawn_configs.clear()
	var main_node := get_parent()
	
	if main_node == null or not ("spawnable_objects" in main_node):
		push_warning("Parent node missing or has no 'spawnable_objects' property!")
		return

	var objects = main_node.get("spawnable_objects")
	if objects == null or objects.is_empty():
		push_warning("Parent node's 'spawnable_objects' array is empty! Assign your ore scenes in the Inspector.")
		return

	for scene in objects:
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
	
	print("Successfully loaded ", spawn_configs.size(), " ore spawn config(s).")


# ---------- Rock discovery ----------

func _is_rock_name(value: Variant) -> bool:
	if not (value is String or value is StringName):
		return false
	return String(value).to_lower().begins_with(rock_prefix.to_lower())


func discover_rock_tiles() -> void:
	rock_tiles.clear()
	if tile_set == null:
		push_warning("No TileSet on the overlay layer, so no rock tiles found.")
		return

	var data_layers: Array[String] = []
	for i in tile_set.get_custom_data_layers_count():
		data_layers.append(tile_set.get_custom_data_layer_name(i))

	for i in tile_set.get_source_count():
		var sid: int = tile_set.get_source_id(i)
		var source: TileSetSource = tile_set.get_source(sid)

		if source is TileSetAtlasSource:
			var atlas := source as TileSetAtlasSource
			var source_match: bool = _is_rock_name(atlas.resource_name)
			if not source_match and atlas.texture != null:
				source_match = _is_rock_name(atlas.texture.resource_path.get_file())

			for t in atlas.get_tiles_count():
				var coords: Vector2i = atlas.get_tile_id(t)
				for a in atlas.get_alternative_tiles_count(coords):
					var alt: int = atlas.get_alternative_tile_id(coords, a)
					var matched: bool = source_match
					if not matched:
						var data: TileData = atlas.get_tile_data(coords, alt)
						for layer_name in data_layers:
							if _is_rock_name(data.get_custom_data(layer_name)):
								matched = true
								break
					if matched:
						rock_tiles.append({"source": sid, "coords": coords, "alt": alt})

		elif source is TileSetScenesCollectionSource:
			var scenes := source as TileSetScenesCollectionSource
			var scenes_match: bool = _is_rock_name(scenes.resource_name)
			for t in scenes.get_scene_tiles_count():
				var tid: int = scenes.get_scene_tile_id(t)
				var packed: PackedScene = scenes.get_scene_tile_scene(tid)
				var file_match: bool = packed != null and _is_rock_name(packed.resource_path.get_file())
				if scenes_match or file_match:
					rock_tiles.append({"source": sid, "coords": Vector2i.ZERO, "alt": tid})

	print("Discovered ", rock_tiles.size(), " rock tile(s) in the TileSet")


func discover_rock_textures() -> void:
	rock_textures.clear()
	_scan_dir(rock_folder)
	print("Discovered ", rock_textures.size(), " rock image(s) under ", rock_folder)
	for tex in rock_textures:
		print("  ", tex.resource_path)


func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Cannot open folder: " + path)
		return

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_scan_dir(path.path_join(entry))
		else:
			# Exported builds list "x.png.import" / "x.png.remap" instead of "x.png"
			var file_name: String = entry.trim_suffix(".import").trim_suffix(".remap")
			if _is_rock_name(file_name) and file_name.get_extension().to_lower() in IMAGE_EXTENSIONS:
				var full_path: String = path.path_join(file_name)
				if ResourceLoader.exists(full_path):
					var tex := load(full_path)
					if tex is Texture2D and not rock_textures.has(tex):
						rock_textures.append(tex)
		entry = dir.get_next()
	dir.list_dir_end()


# ---------- Map generation ----------

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

	if occupied_cells.has(cell):
		return

	# Ores first
	if not spawn_configs.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([active_seed, cell.x, cell.y])

		var order := spawn_configs.duplicate()
		shuffle_array(order, rng)

		for config in order:
			if can_place_at(cell, config, {}) and rng.randf() < config.spawn_chance:
				spawn_cluster(cell, config, rng)
				break

	# Then rocks, only if the cell is still free
	if not occupied_cells.has(cell):
		try_spawn_rock(cell)


func try_spawn_rock(cell: Vector2i) -> void:
	var pool_size: int = rock_tiles.size() + rock_textures.size()
	if pool_size == 0:
		return

	var rock_config := {
		"min_dist": rock_min_distance,
		"max_dist": rock_max_distance
	}
	if not can_place_at(cell, rock_config, {}):
		return

	var rock_rng := RandomNumberGenerator.new()
	rock_rng.seed = hash([active_seed, cell.x, cell.y, "wordentity"])

	if rock_rng.randf() >= rock_spawn_chance:
		return

	var idx: int = rock_rng.randi_range(0, pool_size - 1)
	occupied_cells[cell] = true

	if idx < rock_tiles.size():
		var pick: Dictionary = rock_tiles[idx]
		set_cell(cell, pick.source, pick.coords, pick.alt)
	else:
		var sprite := Sprite2D.new()
		sprite.texture = rock_textures[idx - rock_tiles.size()]
		sprite.position = ground_layer.map_to_local(cell)
		add_child(sprite)


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
