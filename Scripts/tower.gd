# tower.gd
extends StaticBody3D
class_name Tower

enum ProjectileType {
	ARROW,
	CANNONBALL,
	MAGIC
}

# Node references
@onready var tower_mesh: MeshInstance3D = $Base/TowerMesh
@onready var outline_mesh: MeshInstance3D = $Base/OutlineEffect
@onready var range_indicator: MeshInstance3D = $RangeIndicator
@onready var detection_area: Area3D = $DetectionArea
@onready var click_area: Area3D = $ClickArea
@onready var upgrade_ui: Panel

# Tower Stats
var tower_name: String = "Basic Tower"
var tower_level: int = 1
var damage: float = 10.0
var attack_speed: float = 1.0
var attack_range: float = 5.0
var cost: int = 100
var tower_color: Color = Color(0.8, 0.2, 0.2)
var projectile_type: ProjectileType = ProjectileType.ARROW

# VS Mode addition
var is_ai_tower: bool = false

# Scenes
var projectile_scene = preload("res://Scenes/projectile.tscn")

# State
var is_selected: bool = false
var is_hovered: bool = false
var current_target: Enemy = null
var enemies_in_range: Array[Node] = []
var attack_timer: float = 0.0
var is_valid_placement: bool = true

# Materials
var outline_material: StandardMaterial3D
var range_material: StandardMaterial3D
var default_material: StandardMaterial3D
var valid_material: StandardMaterial3D
var invalid_material: StandardMaterial3D

func _ready():
	setup_materials()
	setup_tower()
	setup_collision()
	add_to_group("towers")
  
	print("Tower initialized: ", tower_name)
  
  # Connect signals
	if detection_area:
		detection_area.body_entered.connect(_on_enemy_entered)
		detection_area.body_exited.connect(_on_enemy_exited)
  
  # Get UI reference
	upgrade_ui = get_node("/root/Main/UI/TowerUpgradeUI")

func setup_materials():
  # Setup outline material
	outline_material = StandardMaterial3D.new()
	outline_material.albedo_color = Color(1, 1, 0, 0.5)  # Yellow outline
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  
  # Setup range indicator material
	range_material = StandardMaterial3D.new()
	range_material.albedo_color = Color(0.2, 0.8, 1, 0.2)  # Light blue
	range_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  
  # Setup placement materials
	valid_material = StandardMaterial3D.new()
	valid_material.albedo_color = Color(0, 1, 0, 0.5)
	valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  
	invalid_material = StandardMaterial3D.new()
	invalid_material.albedo_color = Color(1, 0, 0, 0.5)
	invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  
  # Setup default material
	default_material = StandardMaterial3D.new()
	default_material.albedo_color = tower_color

func setup_tower():
	if tower_mesh:
		tower_mesh.material_override = default_material
  
	if outline_mesh:
		outline_mesh.material_override = outline_material
		outline_mesh.visible = false
  
	if range_indicator:
		range_indicator.material_override = range_material
		range_indicator.visible = false

func setup_collision():
  # Set collision layers
	collision_layer = 2  # Tower layer
	collision_mask = 0   # Don't detect collisions
  
	if detection_area:
		detection_area.collision_layer = 2
		detection_area.collision_mask = 4  # Enemy layer
  
	if click_area:
		click_area.collision_layer = 16  # Clickable layer
		click_area.collision_mask = 0

func _input(event):
	var grid_manager = get_node_or_null("/root/Main/GridManager")
	if grid_manager and grid_manager.build_mode:
		return  # Ignore input while in build mode
  
  # Don't process input for AI towers
	if is_ai_tower:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var mouse_pos = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000
	  
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.collision_mask = 2  # Tower layer
			var result = space_state.intersect_ray(query)
	  
			if result and result.collider == self:
				print("Tower clicked:", tower_name)
				show_upgrade_ui()
				get_viewport().set_input_as_handled()

func _process(delta):
	if current_target and is_instance_valid(current_target):
		attack_timer += delta
		if attack_timer >= 1.0 / attack_speed:
			attack()
			attack_timer = 0.0
	elif !enemies_in_range.is_empty():
		select_new_target()

func select_new_target():
	enemies_in_range = enemies_in_range.filter(func(enemy): return is_instance_valid(enemy))
  
	if !enemies_in_range.is_empty():
	# In VS mode, prioritize enemies based on tower owner
		if is_ai_tower:
	  # AI towers prioritize enemies sent by player (target_player = false)
			var ai_targets = enemies_in_range.filter(func(enemy): return !enemy.target_player)
			if !ai_targets.is_empty():
				current_target = ai_targets[0]
				return
		else:
	  # Player towers prioritize enemies targeting player (target_player = true)
			var player_targets = enemies_in_range.filter(func(enemy): return enemy.target_player)
			if !player_targets.is_empty():
				current_target = player_targets[0]
				return
	
	# If no preferred targets, choose first enemy
		current_target = enemies_in_range[0]

func attack():
	if current_target and is_instance_valid(current_target):
		spawn_projectile()
	else:
		current_target = null

func spawn_projectile():
	var projectile = projectile_scene.instantiate()
  
  # Add projectile to the scene tree first before setting global position
	add_child(projectile)
  
  # Set the spawn position to be at the center of the tower
	projectile.global_position = global_position + Vector3(0, 1.0, 0)
  
	projectile.target = current_target
	projectile.damage = damage
	projectile.tower = self
  
  # Get the mesh instance
	var mesh_instance = projectile.get_node("MeshInstance3D")
	if !mesh_instance:
		print("[Tower] Error: Projectile mesh not found")
		return
	
  # Create new material for the projectile
	var projectile_material = StandardMaterial3D.new()
	projectile_material.albedo_color = tower_color
	projectile_material.emission_enabled = true
	projectile_material.emission = tower_color
	mesh_instance.material_override = projectile_material
  
  # Set projectile properties based on type
	match projectile_type:
		ProjectileType.ARROW:
			projectile.speed = 40.0  # Faster arrows
			projectile.scale = Vector3(0.3, 0.3, 1)
		ProjectileType.CANNONBALL:
			projectile.speed = 25.0  # Slower but still fast cannonballs
			projectile.scale = Vector3(0.5, 0.5, 0.5)
		ProjectileType.MAGIC:
			projectile.speed = 35.0  # Fast magic projectiles
  
	add_child(projectile)

func _on_enemy_entered(body: Node3D):
	if body is Enemy:
		enemies_in_range.append(body)
		if !current_target:
			select_new_target()

func _on_enemy_exited(body: Node3D):
	if body is Enemy:
		enemies_in_range.erase(body)
		if current_target == body:
			current_target = null
			select_new_target()

func set_placement_valid(valid: bool):
	is_valid_placement = valid
	if tower_mesh:
		tower_mesh.material_override = valid_material if valid else invalid_material

func set_final_material():
	if tower_mesh:
		tower_mesh.material_override = default_material

func show_upgrade_ui():
	if upgrade_ui and !is_ai_tower:  # Don't show upgrade UI for AI towers
		upgrade_ui.show_for_tower(self)

func upgrade():
	tower_level += 1
	damage *= 1.5
	attack_speed *= 1.2
	attack_range *= 1.1
  
  # Scale up the tower slightly
	var scale_factor = 1.0 + (tower_level - 1) * 0.2
	if tower_mesh:
		tower_mesh.scale = Vector3(1, scale_factor, 1)
	if outline_mesh:
		outline_mesh.scale = Vector3(1, scale_factor, 1) * 1.1
  
  # Update range
	if detection_area:
		var shape = detection_area.get_node_or_null("CollisionShape3D")
		if shape and shape.shape is SphereShape3D:
			shape.shape.radius = attack_range
  
	if range_indicator and range_indicator.mesh is CylinderMesh:
		range_indicator.mesh.top_radius = attack_range
		range_indicator.mesh.bottom_radius = attack_range

func get_upgrade_cost() -> int:
	return cost * tower_level * 2

func get_sell_value() -> int:
	var total_spent = cost
	for level in range(1, tower_level):
		total_spent += cost * level * 2
	return int(total_spent * 0.5)
  
func deselect():
	is_selected = false
	if upgrade_ui and upgrade_ui.current_tower == self:
		upgrade_ui.visible = false
