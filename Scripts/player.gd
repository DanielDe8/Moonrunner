extends CharacterBody2D


@export var speed = 400

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed 

func _physics_process(_delta: float) -> void:
	get_input()
	
	if velocity.x > 0 or velocity.y > 0:
		$AnimatedSprite2D.play("move_right")
	elif velocity.x < 0 or velocity.y < 0:
		$AnimatedSprite2D.play("move_left")
	else:
		$AnimatedSprite2D.pause()
	
	move_and_slide()
