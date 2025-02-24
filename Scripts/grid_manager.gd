# grid_manager.gd
extends Node3D

signal build_mode_changed(is_building: bool)

var grid_size = 1.0
var grid_width = 2
var grid_height = 20
var occupied_positions = {}

# VS Mode additions
var player_occupied_positions = {}
var ai_occupied_positions = {}

var placeholder_tower: Node3D
var valid_material: StandardMaterial3D
var invalid_material: StandardMaterial3D

var tower_manager: Node
var game_manager: Node

var build_mode: bool = false:
	set(value):
		if build_mode != value:
			build_mode = value
			build_mode_changed.emit(build_mode)
			print("Build mode changed to: ", build_mode)
			if build_mode:
				deselect_all_towers()

func _ready():
	tower_manager = get_node("/root/Main/TowerManager")
	game_manager = get_node("/root/Main/GameManager")
  
  # Setup placeholder materials
	valid_material = StandardMaterial3D.new()
	valid_material.albedo_color = Color(0, 1, 0, 0.5)
	valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  
	invalid_material = StandardMaterial3D.new()
	invalid_material.albedo_color = Color(1, 0, 0, 0.5)
	invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func enter_build_mode(tower_type: int):
	self.build_mode = true  # Using setter
	create_placeholder(tower_type)

func exit_build_mode():
	self.build_mode = false  # Using setter
	if placeholder_tower:
		placeholder_tower.queue_free()
		placeholder_tower = null

func deselect_all_towers():
	var towers = get_tree().get_nodes_in_group("towers")
	for tower in towers:
		tower.deselect()

func create_placeholder(tower_type: int):
	if placeholder_tower:
		placeholder_tower.queue_free()
  
	placeholder_tower = tower_manager.create_tower(tower_type)
	placeholder_tower.visible = false
	add_child(placeholder_tower)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if build_mode:
				place_tower_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
	  # Right click exits build mode
			exit_build_mode()

func _process(_delta):
	if build_mode and placeholder_tower:
		update_placeholder_position()

func update_placeholder_position():
	var camera = get_node("/root/Main/Camera3D")
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
  
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
  
	if result:
		var grid_pos = get_grid_position(result.position)
		var world_pos = get_world_position(grid_pos)
	
		placeholder_tower.visible = true
		placeholder_tower.position = world_pos
	
	# Check placement validity
		var can_afford = game_manager.can_afford(tower_manager.get_tower_cost(tower_manager.selected_tower_type))
		var valid_position = is_valid_build_position(grid_pos) and !occupied_positions.has(grid_pos)
	
		placeholder_tower.set_placement_valid(valid_position and can_afford)
	else:
		placeholder_tower.visible = false

func place_tower_at_mouse():
	var camera = get_node("/root/Main/Camera3D")
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
  
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
  
	if result:
		var grid_pos = get_grid_position(result.position)
		var valid_position = is_valid_build_position(grid_pos) and !occupied_positions.has(grid_pos)
	
		if valid_position:
			var tower_cost = tower_manager.get_tower_cost(tower_manager.selected_tower_type)
			if game_manager.can_afford(tower_cost):
				create_tower(grid_pos)
				game_manager.remove_gold(tower_cost)
				exit_build_mode()  # Exit build mode after placing tower

func create_tower(grid_pos: Vector2):
	var tower = tower_manager.create_tower(tower_manager.selected_tower_type)
	var world_pos = get_world_position(grid_pos)
	tower.position = world_pos
	add_child(tower)
	tower.set_final_material()
	occupied_positions[grid_pos] = true
	player_occupied_positions[grid_pos] = true  # For VS Mode

func get_grid_position(world_position: Vector3) -> Vector2:
	var grid_x = floor(world_position.x / grid_size)
	var grid_z = floor(world_position.z / grid_size)
	return Vector2(grid_x, grid_z)

func get_world_position(grid_pos: Vector2) -> Vector3:
	return Vector3(grid_pos.x * grid_size + 0.5, 0, grid_pos.y * grid_size + 0.5)

func is_valid_build_position(grid_pos: Vector2) -> bool:
	if occupied_positions.has(grid_pos):
		return false
	
	# Player's build areas (x = -7 or x = -5)
	if (grid_pos.x >= -7 and grid_pos.x <= -6) or (grid_pos.x >= -5 and grid_pos.x <= -4):
		return true
	
	# AI's build areas (x = 5 or x = 7)
	if (grid_pos.x >= 5 and grid_pos.x <= 6) or (grid_pos.x >= 7 and grid_pos.x <= 8):
		return true
	
	return false

# VS Mode additions
func get_available_positions(owner: String) -> Array:
	var available = []
	var grid_positions
	
	if owner == "player":
		# Player grid is on the left sides
		var positions1 = get_grid_range(Vector2(-7, -10), Vector2(-6, 10))  # First build area
		var positions2 = get_grid_range(Vector2(-5, -10), Vector2(-4, 10))  # Second build area
		grid_positions = positions1 + positions2
	else:
		# AI grid is on the right sides
		var positions1 = get_grid_range(Vector2(5, -10), Vector2(6, 10))  # First build area
		var positions2 = get_grid_range(Vector2(7, -10), Vector2(8, 10))  # Second build area
		grid_positions = positions1 + positions2
	
	# Filter out occupied positions
	for pos in grid_positions:
		var occupied = player_occupied_positions.has(pos) if owner == "player" else ai_occupied_positions.has(pos)
		if !occupied:
			available.append(pos)
		
	return available

# Get all grid positions in a range
func get_grid_range(start: Vector2, end: Vector2) -> Array:
	var positions = []
	for x in range(start.x, end.x + 1):
		for z in range(start.y, end.y + 1):
			positions.append(Vector2(x, z))
	return positions

# Get tower count by owner
func get_tower_count(owner: String) -> int:
	if owner == "player":
		return player_occupied_positions.size()
	else:
		return ai_occupied_positions.size()

# Create tower for AI
func create_ai_tower(grid_pos: Vector2, tower_type: int):
	var tower = tower_manager.create_tower(tower_type)
	var world_pos = get_world_position(grid_pos)
	tower.position = world_pos
	tower.is_ai_tower = true
	add_child(tower)
	tower.set_final_material()
	ai_occupied_positions[grid_pos] = true
	occupied_positions[grid_pos] = true  # For compatibility with existing code

# VS Mode lane setup
func setup_vs_lanes():
	# Clear existing lanes if any
	var existing_lanes = get_tree().get_nodes_in_group("lanes")
	for lane in existing_lanes:
		lane.queue_free()
	
	# Create player lanes
	var player_build_lane1 = create_lane("player_build_lane1", Vector3(-7, 0, 0), Color(0.2, 0.5, 0.2, 0.5))
	var player_enemy_lane = create_lane("player_enemy_lane", Vector3(-6, 0, 0), Color(0.3, 0.3, 0.3))
	var player_build_lane2 = create_lane("player_build_lane2", Vector3(-5, 0, 0), Color(0.2, 0.5, 0.2, 0.5))
	
	# Create AI lanes
	var ai_build_lane1 = create_lane("ai_build_lane1", Vector3(5, 0, 0), Color(0.2, 0.5, 0.2, 0.5))
	var ai_enemy_lane = create_lane("ai_enemy_lane", Vector3(6, 0, 0), Color(0.3, 0.3, 0.3))
	var ai_build_lane2 = create_lane("ai_build_lane2", Vector3(7, 0, 0), Color(0.2, 0.5, 0.2, 0.5))


func create_lane(name: String, position: Vector3, color: Color) -> MeshInstance3D:
	var lane_mesh = PlaneMesh.new()
	lane_mesh.size = Vector2(1.0, 20.0)  # 1 unit wide for clearer separation
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var lane = MeshInstance3D.new()
	lane.name = name
	lane.mesh = lane_mesh
	lane.position = position
	lane.material_override = material
	lane.add_to_group("lanes")
	
	add_child(lane)
	return lane
