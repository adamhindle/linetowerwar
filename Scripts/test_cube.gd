extends StaticBody3D

@onready var mesh_instance = $MeshInstance3D
var upgrade_ui: Panel
var normal_color = Color(0.2, 0.8, 0.2)  # Green
var clicked_color = Color(0.8, 0.2, 0.2)  # Red
var is_clicked = false

func _ready():
	print("Test cube initialized")
	# Set up initial material
	var material = StandardMaterial3D.new()
	material.albedo_color = normal_color
	mesh_instance.material_override = material
	
	# Get reference to upgrade UI
	upgrade_ui = get_node("/root/Main/UI/TowerUpgradeUI")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var mouse_pos = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.collision_mask = 32  # Layer 6 for test cube
			var result = space_state.intersect_ray(query)
			
			if result and result.collider == self:
				print("Direct raycast hit on test cube!")
				toggle_color()
				show_upgrade_ui()
				get_viewport().set_input_as_handled()

func toggle_color():
	is_clicked = !is_clicked
	var material = mesh_instance.material_override
	material.albedo_color = clicked_color if is_clicked else normal_color
	print("Color changed to: ", "red" if is_clicked else "green")

func show_upgrade_ui():
	if upgrade_ui:
		# Position UI at mouse position
		var mouse_pos = get_viewport().get_mouse_position()
		upgrade_ui.position = mouse_pos
		upgrade_ui.show_for_tower(self)  # We'll need to make the UI handle non-tower objects
