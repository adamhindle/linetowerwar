# camera_3d.gd
extends Camera3D

var camera_speed = 10.0
var camera_height = 10.0
var grid_manager: Node

func _ready():
	# Position camera
	position = Vector3(0, camera_height, camera_height)
	rotation_degrees = Vector3(-45, 0, 0)  # Looking down at an angle
	
	# Camera settings
	projection = Camera3D.PROJECTION_PERSPECTIVE
	fov = 45.0  # Lower FOV for better perspective
	
	# Get grid manager reference
	grid_manager = get_node("/root/Main/GridManager")

func _process(delta):
	# Camera movement
	handle_camera_movement(delta)

func handle_camera_movement(delta):
	if Input.is_action_pressed("ui_up"):
		position.z -= camera_speed * delta
	if Input.is_action_pressed("ui_down"):
		position.z += camera_speed * delta
	if Input.is_action_pressed("ui_left"):
		position.x -= camera_speed * delta
	if Input.is_action_pressed("ui_right"):
		position.x += camera_speed * delta
