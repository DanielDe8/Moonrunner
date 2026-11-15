extends CharacterBody2D
## Player rover controller: 8-way movement, camera zoom, animations, and battery/respawn.

# --- Movement & Animation ---
@export var speed = 400
@export var start_delay = 0.05   # Seconds of movement before tilting the antenna
@export var stop_delay = 0.08    # Seconds of stillness before centering the antenna

# --- Camera Zoom ---
@export var min_zoom: float = 1.0
@export var max_zoom: float = 8.0
@export var zoom_step: float = 0.4
@export var zoom_smooth_speed: float = 10.0

# --- Battery ---
@export var max_battery_life: float = 100.0
@export var idle_battery_consumption: float = 1.0
@export var moving_battery_consumption: float = 3.0
@export var warp_battery_consumption: float = 10.0
@export var mining_battery_consumption: float = 20.0
@export var is_mining = false

@export var time_to_warp_back = 3.0

var battery_life = max_battery_life
var motion_timer = 0.0
var stop_timer = 0.0
var target_zoom: float = 4.0

@onready var camera: Camera2D = $Camera2D
@onready var charging_area: Area2D = $"../Camp/ChargingArea"
var hud_string = "../CanvasLayer"

var last_pos_array: Array[Vector2] = []

var red_ore_count: int = 0
var scrap_count: int = 0

func _ready() -> void:
	if camera != null:
		target_zoom = camera.zoom.x
	
	$PosSaveTimer.timeout.connect(func() -> void:
		last_pos_array.append(global_position)

		var max_positions = ceili(time_to_warp_back / $PosSaveTimer.wait_time)

		while last_pos_array.size() > max_positions:
			print(last_pos_array.pop_front())
	)
	

## Handles mouse wheel and +/- key camera zoom input.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom + zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom - zoom_step, min_zoom, max_zoom)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			target_zoom = clamp(target_zoom + zoom_step, min_zoom, max_zoom)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			target_zoom = clamp(target_zoom - zoom_step, min_zoom, max_zoom)


## Reads directional input and sets movement velocity.
func get_input() -> void:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed


## Updates movement, antenna, and mining animations based on current state.
func update_animations(delta: float) -> void:
	# Play directional rover tread animation, or pause when stationary.
	if velocity.x > 0:
		$MovementAnimation.play("move_right")
	elif velocity.x < 0:
		$MovementAnimation.play("move_left")
	elif velocity.y < 0:
		$MovementAnimation.play("move_right")
	elif velocity.y > 0:
		$MovementAnimation.play("move_left")
	else:
		$MovementAnimation.pause()

	# Tilt the antenna in the horizontal movement direction after a short delay.
	if velocity != Vector2.ZERO:
		stop_timer = 0.0
		motion_timer += delta

		if motion_timer >= start_delay:
			if velocity.x > 0:
				$AntennaAnimation.frame = 0
			elif velocity.x < 0:
				$AntennaAnimation.frame = 2
	else:
		motion_timer = 0.0
		stop_timer += delta

		if stop_timer >= stop_delay:
			$AntennaAnimation.frame = 1
		
	# Emit tread dust particles only while the rover is moving.
	if has_node("GPUParticles2D"):
		$GPUParticles2D.emitting = (velocity != Vector2.ZERO)

	# Mining animation & red spark/chip particles
	if has_node("MiningParticles"):
		$MiningParticles.emitting = is_mining
	if is_mining:
		$MiningAnimation.show()
		$MiningAnimation.play("default")
	else:
		$MiningAnimation.hide()
		$MiningAnimation.pause()
		
	$"../Silo".update_ore_visual(red_ore_count)

## Updates battery charge/drain, HUD label, and respawns at camp if depleted.
func check_battery(delta: float) -> void:
	# Recharge inside the camp's ChargingArea; otherwise drain based on idle, moving, and mining.
	if charging_area.overlaps_body(self):
		battery_life = min(battery_life + delta * 20, max_battery_life)
	elif not $"../Camp/Area2D".overlaps_body(self):
		battery_life -= idle_battery_consumption * delta
		if velocity != Vector2.ZERO:
			battery_life -= moving_battery_consumption * delta
		if is_mining:
			battery_life -= mining_battery_consumption * delta

	# Update the on-rover battery sprite and HUD percentage label.
	var battery_percentage = (battery_life / max_battery_life)
	$BatteryAnimation.frame = battery_percentage * ($BatteryAnimation.sprite_frames.get_frame_count($BatteryAnimation.animation) - 1)

	get_node("%s/HUD/BatteryLabel" % hud_string).text = str(battery_percentage * 100).pad_decimals(0) + "%"

	# Respawn back at the charging area with a full battery when depleted.
	if battery_percentage <= 0.0:
		global_position = charging_area.global_position
		battery_life = max_battery_life


func check_mining(delta: float) -> void:
	is_mining = false
	
	if Input.is_action_pressed("mine"):
		for collectable in get_tree().get_nodes_in_group("Collectables"):
			if collectable.overlaps_body(self):
				is_mining = true
				collectable.mine(delta)


func update_hud() -> void:
	get_node("%s/HUD/RedOreLabel" % hud_string).text = str(red_ore_count)
	get_node("%s/HUD/ScrapLabel" % hud_string).text = str(scrap_count)


func _physics_process(delta: float) -> void:
	# Smooth camera zoom
	if camera != null:
		var z: float = lerp(camera.zoom.x, target_zoom, clamp(delta * zoom_smooth_speed, 0.0, 1.0))
		camera.zoom = Vector2(z, z)

	if Input.is_action_pressed("warp") && battery_life > warp_battery_consumption && len(last_pos_array) >= time_to_warp_back / $PosSaveTimer.wait_time:
		battery_life = battery_life - warp_battery_consumption
		global_position = last_pos_array[0]
		last_pos_array.clear()
			
	get_input()
	update_animations(delta)
	check_battery(delta)
	check_mining(delta)
	update_hud()

	move_and_slide()
