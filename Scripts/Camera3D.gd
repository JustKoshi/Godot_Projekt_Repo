extends Camera3D

var radius = 20.0
var angle = -40.0
var speed = 0.5

# Center of circle (Camera moves around this point)
var center = Vector3(0, 20, 0)
var tilt_value = -20

func _ready():
	#initial position of camera
	var initial_pos = Vector3(7, 20, 15)
	var offset = initial_pos - center
	angle = atan2(offset.x, offset.z)

func _process(delta):
	# Sprawdzanie naciśnięcia klawiszy
	if Input.is_action_pressed("move_left"):
			angle -= speed * delta  # W lewo (klawisz "Q")
	elif Input.is_action_pressed("move_right"):
			angle += speed * delta  # W prawo (klawisz "E")
	
	# Obliczanie nowej pozycji kamery na okręgu
	var new_x = center.x + radius * sin(angle)
	var new_z = center.z + radius * cos(angle)
	var new_position = Vector3(new_x, center.y, new_z)

# Ustawianie nowej pozycji kamery
	global_transform.origin = new_position
	
	# Kamera patrzy w stronę środka z offsetem pionowym, żeby patrzyła bardziej w dół
	var look_target = center + Vector3(0, tilt_value, 0)
	look_at(look_target, Vector3.UP)
