# enemy.gd
extends CharacterBody3D
class_name Enemy

# Enemy Stats
@export var enemy_name: String = "Basic Enemy"
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var movement_speed: float = 1.0
@export var gold_value: int = 1
@export var damage_to_base: int = 1
@export var enemy_color: Color = Color(1, 0, 0)  # Default red color

# Movement
var path_points: Array[Vector3] = []
var current_point_index: int = 0
var path_progress: float = 0.0

# VS Mode addition
var target_player: bool = true  # If false, targets AI base

# References
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var health_bar: Node3D = $HealthBar

signal enemy_died(enemy: Enemy)
signal enemy_reached_end(enemy: Enemy)
signal health_changed(current_health: float, max_health: float)

func _ready():
	print("[Enemy] Initializing enemy: ", enemy_name)
  
	# Set collision layer to 4 (enemy layer) and make sure we're a proper physics body
	collision_layer = 4
	collision_mask = 0  # Don't detect collisions with anything
	
	# Add to enemies group for easier management
	add_to_group("enemies")
  
	setup_enemy_mesh()
	setup_health_bar()
	current_health = max_health
  
	# Only generate path if no custom path is set
	if path_points.is_empty():
		generate_path()
	
	print("[Enemy] Setup complete. Health: ", current_health, " - Path: ", path_points)

func setup_enemy_mesh():
	if !mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
  
	var mesh = BoxMesh.new()
	mesh_instance.mesh = mesh
	mesh_instance.scale = Vector3(0.8, 0.8, 0.8)  # Slightly smaller than towers
  
	var material = StandardMaterial3D.new()
	material.albedo_color = enemy_color
	mesh_instance.material_override = material

func setup_health_bar():
	if !health_bar:
		health_bar = Node3D.new()
		health_bar.name = "HealthBar"
		add_child(health_bar)
  
	# Create health bar mesh (green bar)
	var bar_mesh = BoxMesh.new()
	var bar_instance = MeshInstance3D.new()
	bar_instance.mesh = bar_mesh
	bar_instance.scale = Vector3(1, 0.1, 0.1)  # Thin bar
	bar_instance.position.y = 1.2  # Above enemy
  
	var bar_material = StandardMaterial3D.new()
	bar_material.albedo_color = Color(0, 1, 0)
	bar_instance.material_override = bar_material
  
	health_bar.add_child(bar_instance)

func generate_path():
	# Generate path points along the lane
	path_points.clear()
  
	# Default path for single lane mode in endless mode
	# This should be overridden by the enemy_manager in VS mode
	path_points.append(Vector3(0, 0.5, -10))  # Start point
	path_points.append(Vector3(0, 0.5, 10))   # End point
	
	print("[Enemy] Generated default path")

func _process(delta):
	move_along_path(delta)
	update_health_bar()

func move_along_path(delta):
	if current_point_index >= path_points.size() - 1:
		reached_end()
		return
	
	var start_point = path_points[current_point_index]
	var end_point = path_points[current_point_index + 1]
  
	path_progress += movement_speed * delta
	if path_progress >= 1.0:
		path_progress = 0.0
		current_point_index += 1
		return
  
	var new_position = start_point.lerp(end_point, path_progress)
	position = new_position

func update_health_bar():
	var health_percentage = current_health / max_health
	if health_bar and health_bar.get_child_count() > 0:
		health_bar.get_child(0).scale.x = max(health_percentage, 0)
	
		# Update color based on health percentage
		var bar_material = health_bar.get_child(0).material_override as StandardMaterial3D
		if bar_material:
			bar_material.albedo_color = Color(1 - health_percentage, health_percentage, 0)

func take_damage(amount: float):
	print("[Enemy] Taking damage: ", amount, " Current health: ", current_health)
	current_health -= amount
	health_changed.emit(current_health, max_health)
	print("[Enemy] Health after damage: ", current_health)
  
	if current_health <= 0:
		print("[Enemy] Enemy died from damage")
		die()

func die():
	enemy_died.emit(self)
	queue_free()

func reached_end():
	print("[Enemy] Reached end! Path: ", path_points, ", Target player: ", target_player)
	enemy_reached_end.emit(self)
  
	# In VS mode, determine which base to damage based on target_player flag
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager.is_vs_mode:
		if target_player:
			print("[Enemy] Dealing ", damage_to_base, " damage to player base")
			game_manager.take_base_damage(damage_to_base)
		else:
			print("[Enemy] Dealing ", damage_to_base, " damage to AI base")
			game_manager.take_ai_base_damage(damage_to_base)
	else:
		# Legacy behavior for endless mode
		print("[Enemy] Endless mode - Dealing ", damage_to_base, " damage to base")
		game_manager.take_base_damage(damage_to_base)
	
	queue_free()
