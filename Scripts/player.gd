extends CharacterBody2D

@export var speed = 400
@export var start_delay = 0.05
@export var stop_delay = 0.08
@export var min_zoom: float = 1.0
@export var max_zoom: float = 8.0
@export var zoom_step: float = 0.4
@export var zoom_smooth_speed: float = 10.0
@export var max_battery_life: float = 100.0
@export var idle_battery_consumption: float = 1.0
@export var moving_battery_consumption: float = 3.0
@export var warp_battery_consumption: float = 10.0

var battery_life = max_battery_life

var motion_timer = 0.0
var stop_timer = 0.0
var target_zoom: float = 4.0

@onready var camera: Camera2D = $Camera2D
@onready var charging_area: Area2D = $"../Camp/ChargingArea"


func _ready() -> void:
	if camera != null:
		target_zoom = camera.zoom.x


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


func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed


func _physics_process(delta: float) -> void:
	# Smooth camera zoom
	if camera != null:
		var z: float = lerp(camera.zoom.x, target_zoom, clamp(delta * zoom_smooth_speed, 0.0, 1.0))
		camera.zoom = Vector2(z, z)

	get_input()

	# Movement animation
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

	# Antenna animation
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

	# Battery
	if charging_area.overlaps_body(self):
		battery_life = min(battery_life + delta * 10, max_battery_life)
	elif velocity == Vector2.ZERO:
		battery_life -= idle_battery_consumption * delta
	else:
		battery_life -= moving_battery_consumption * delta

	var battery_percentage = (battery_life / max_battery_life)
	$BatteryAnimation.frame = battery_percentage * ($BatteryAnimation.sprite_frames.get_frame_count($BatteryAnimation.animation) - 1)

	$"../CanvasLayer/HUD/Label".text = str(battery_percentage * 100).pad_decimals(0) + "%"

	# Out of battery: respawn at the charging area
	if battery_percentage <= 0.0:
		global_position = charging_area.global_position
		battery_life = max_battery_life

	move_and_slide()
