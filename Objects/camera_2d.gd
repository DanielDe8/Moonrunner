extends Camera2D

@export var amplitude := 1.5        # pixels, keep 1-2 for subtle
@export var frequency := 60.0       # vibration speed, higher = buzzier
@export var fade_speed := 8.0       # how fast it ramps in/out

var drilling := false
var intensity := 0.0
var t := 0.0
var noise := FastNoiseLite.new()

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 1.0

func set_drilling(value: bool) -> void:
	drilling = value

func _process(delta: float) -> void:
	var target := 1.0 if drilling else 0.0
	intensity = move_toward(intensity, target, fade_speed * delta)

	if intensity > 0.001:
		t += delta * frequency
		offset = Vector2(
			noise.get_noise_2d(t, 0.0),
			noise.get_noise_2d(0.0, t + 100.0)
		) * amplitude * intensity
	else:
		offset = Vector2.ZERO
