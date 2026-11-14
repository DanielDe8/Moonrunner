extends Node2D
## Main level script: plans a 500-block world around the camp and streams floor + ores near the player.

## All 8 neighboring tile offsets (orthogonal + diagonal).
const DIRS_8: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1,  0),                  Vector2i(1,  0),
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1),
]

## TileSet source ID and atlas coordinates for the 4 planet surface floor variants.
const SURFACE_SOURCE_ID: int = 1
const SURFACE_TILES: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

## Ore scenes to pick from when spawning clusters.
@export var ore_scenes: Array[PackedScene] = []
## Maximum distance (in blocks/tiles) from the camp where floor and ores exist.
@export var spawn_radius: int = 500
## Minimum safe distance (in blocks/tiles) from the camp for ores.
@export var min_distance: int = 5
## Number of random starting ore locations to plan across the 500-block map.
@export var ore_cluster_count: int = 2500
## 1-in-N chance for each of the 8 surrounding squares to spawn another ore (default: 1 in 6).
@export var spread_chance_denominator: int = 6
## Maximum number of ores allowed in a single cluster.
@export var max_cluster_size: int = 6
## Radius (in tiles) around the player to actually place floor tiles and ore nodes.
@export var view_radius: int = 35

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var camp: Node2D = $Camp
@onready var player: CharacterBody2D = $player

var _center_cell := Vector2i.ZERO
var _ores_parent: Node2D = null
var _last_player_cell := Vector2i(999999, 999999)

## Planned ores waiting to be instantiated when the player gets within view_radius (cell -> PackedScene).
var _pending_ores: Dictionary = {}
## Cells already planned for ores (so clusters don't overlap).
var _planned_cells: Dictionary = {}
## Floor cells already placed on TileMapLayer.
var _placed_floor: Dictionary = {}


func _ready() -> void:
	if tile_map == null or camp == null or player == null:
		return

	_ores_parent = Node2D.new()
	_ores_parent.name = "Ores"
	add_child(_ores_parent)

	_center_cell = tile_map.local_to_map(tile_map.to_local(camp.global_position))
	# Plan all ore clusters in memory (fast, no nodes or tiles created yet).
	_plan_all_ores()
	# Spawn only the floor tiles and ores visible around the player right now.
	_update_visible_area()


func _physics_process(_delta: float) -> void:
	_update_visible_area()


## Plans all ore clusters across the 500-block ring in memory without instantiating nodes yet.
func _plan_all_ores() -> void:
	if ore_scenes.is_empty():
		return

	var min_sq := float(min_distance * min_distance)
	var max_sq := float(spawn_radius * spawn_radius)

	for i in ore_cluster_count:
		var angle := randf() * TAU
		var dist := sqrt(randf_range(min_sq, max_sq))
		var start_cell := _center_cell + Vector2i(roundi(cos(angle) * dist), roundi(sin(angle) * dist))
		if _planned_cells.has(start_cell):
			continue

		var ore_scene: PackedScene = ore_scenes.pick_random()
		if ore_scene == null:
			continue

		_plan_cluster(ore_scene, start_cell)


## Expands a single ore cluster using a 1-in-6 chance across the 8 surrounding squares.
func _plan_cluster(ore_scene: PackedScene, start_cell: Vector2i) -> void:
	var queue: Array[Vector2i] = [start_cell]
	_planned_cells[start_cell] = true
	_pending_ores[start_cell] = ore_scene
	var cluster_size := 1

	while not queue.is_empty() and cluster_size < max_cluster_size:
		var current: Vector2i = queue.pop_front()
		for offset in DIRS_8:
			if cluster_size >= max_cluster_size:
				break

			var neighbor := current + offset
			if _planned_cells.has(neighbor):
				continue

			if randi_range(1, spread_chance_denominator) == 1:
				_planned_cells[neighbor] = true
				_pending_ores[neighbor] = ore_scene
				queue.append(neighbor)
				cluster_size += 1


## Places floor tiles and instantiates planned ores within view_radius of the player (inside spawn_radius).
func _update_visible_area() -> void:
	var player_cell := tile_map.local_to_map(tile_map.to_local(player.global_position))
	if player_cell == _last_player_cell:
		return
	_last_player_cell = player_cell

	var world_r_sq := spawn_radius * spawn_radius
	var view_r_sq := view_radius * view_radius

	for x in range(player_cell.x - view_radius, player_cell.x + view_radius + 1):
		var dx_view := x - player_cell.x
		var dx_world := x - _center_cell.x
		var dx_view_sq := dx_view * dx_view
		var dx_world_sq := dx_world * dx_world

		for y in range(player_cell.y - view_radius, player_cell.y + view_radius + 1):
			var dy_view := y - player_cell.y
			if dx_view_sq + dy_view * dy_view > view_r_sq:
				continue

			var dy_world := y - _center_cell.y
			if dx_world_sq + dy_world * dy_world > world_r_sq:
				continue

			var cell := Vector2i(x, y)
			if not _placed_floor.has(cell):
				_placed_floor[cell] = true
				tile_map.set_cell(cell, SURFACE_SOURCE_ID, SURFACE_TILES[randi() % 4])

			if _pending_ores.has(cell):
				var ore_scene: PackedScene = _pending_ores[cell]
				_pending_ores.erase(cell)
				var ore := ore_scene.instantiate() as Node2D
				if ore != null:
					_ores_parent.add_child(ore)
					ore.global_position = tile_map.to_global(tile_map.map_to_local(cell))
