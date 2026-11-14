extends CharacterBody2D


@export var speed = 400

func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down").normalized() 

func _physics_process(delta: float) -> void:
	var direction = get_input()
	
	if direction.x > 0 || direction.y > 0:
		$AnimatedSprite2D.play("move_right")
	elif direction.x < 0 || direction.y < 0:
		$AnimatedSprite2D.play("move_left")
	else:
		$AnimatedSprite2D.pause()
	
	velocity = direction * speed
	move_and_slide()
