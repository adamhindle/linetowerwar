# main.gd
extends Node3D

@onready var grid_manager = $GridManager

func _ready():
	setup_lane()
	setup_build_areas()
  
  # Add new manager nodes
	var game_mode_manager = load("res://Scripts/game_mode_manager.gd").new()
	game_mode_manager.name = "GameModeManager"
	add_child(game_mode_manager)
  
	var ai_manager = load("res://Scripts/ai_manager.gd").new()
	ai_manager.name = "AIManager"
	add_child(ai_manager)
  
  # Show game mode selection on start
	$UI/ModeSelectionPanel.visible = true

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
	  # Exit build mode on right click
			grid_manager.exit_build_mode()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		grid_manager.exit_build_mode()

func setup_lane():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(1.0, 20.0)  # Make lanes 1 unit wide
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3)
	
	# Create center lane for endless mode
	$Lane.mesh = plane_mesh
	$Lane.material_override = material
	$Lane.position = Vector3(0, 0, 0)  # Center position

func setup_build_areas():
	var build_area_mesh = PlaneMesh.new()
	build_area_mesh.size = Vector2(2.0, 20.0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.2, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Left build area setup
	$BuildArea_Left.mesh = build_area_mesh
	$BuildArea_Left.position = Vector3(-2.0, 0, 0)  # Place next to center lane
	$BuildArea_Left.material_override = material
	
	# Right build area setup
	$BuildArea_Right.mesh = build_area_mesh
	$BuildArea_Right.position = Vector3(2.0, 0, 0)  # Place next to center lane
	$BuildArea_Right.material_override = material
	
	# Update collision shapes
	var left_shape = BoxShape3D.new()
	left_shape.size = Vector3(2.0, 0.1, 20.0)
	$BuildArea_Left/StaticBody3D/CollisionShape3D.shape = left_shape
	
	var right_shape = BoxShape3D.new()
	right_shape.size = Vector3(2.0, 0.1, 20.0)
	$BuildArea_Right/StaticBody3D/CollisionShape3D.shape = right_shape
