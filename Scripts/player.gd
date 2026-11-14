extends CharacterBody2D


@export var speed = 400
@export var start_delay = 0.05
@export var stop_delay = 0.08

var motion_timer = 0.0
var stop_timer = 0.0

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed 

func _physics_process( delta: float) -> void:
	get_input()
	
	if velocity.x > 0 or velocity.y > 0:
		$MovementAnimation.play("move_right")
	elif velocity.x < 0 or velocity.y < 0:
		$MovementAnimation.play("move_left")
	else:
		$MovementAnimation.pause()
		

	if velocity != Vector2.ZERO:
		stop_timer = 0.0
		motion_timer += delta
		
		# Trigger animations and antenna tilt after start_delay
		if motion_timer >= start_delay:
			if velocity.x > 0 or velocity.y > 0:
				$MovementAnimation.play("move_right")
			elif velocity.x < 0 or velocity.y < 0:
				$MovementAnimation.play("move_left")
				
			if velocity.x > 0:
				$AnimatedSprite2D.frame = 0   # right
			elif velocity.x < 0:
				$AnimatedSprite2D.frame = 2   # left
	else:
		motion_timer = 0.0
		stop_timer += delta
		$MovementAnimation.pause()
		
		# Snap antenna back to still only after stop_delay passes
		if stop_timer >= stop_delay:
			$AnimatedSprite2D.frame = 1   # still
	
	move_and_slide()
