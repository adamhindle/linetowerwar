# enemy_manager.gd
extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()

var enemy_scene = preload("res://Scenes/enemy.tscn")
var current_wave: Wave
var current_wave_number: int = 0
var enemies_remaining: int = 0
var enemies_alive: int = 0
var spawn_timer: float = 0.0
var wave_in_progress: bool = false
var current_enemy_index: int = 0
var current_enemy_type_index: int = 0

var enemy_data = {
	GameEnums.EnemyType.BASIC: {
		"name": "Basic Enemy",
		"health": 100.0,
		"speed": 0.1,
		"gold": 10,
		"damage": 1,
		"color": Color(0.8, 0.2, 0.2)
	},
	GameEnums.EnemyType.FAST: {
		"name": "Fast Enemy",
		"health": 75.0,
		"speed": 0.2,
		"gold": 15,
		"damage": 1,
		"color": Color(0.2, 0.8, 0.2)
	},
	GameEnums.EnemyType.TANK: {
		"name": "Tank Enemy",
		"health": 200.0,
		"speed": 0.1,
		"gold": 20,
		"damage": 2,
		"color": Color(0.2, 0.2, 0.8)
	},
	GameEnums.EnemyType.BOSS: {
		"name": "Boss Enemy",
		"health": 500.0,
		"speed": 0.05,
		"gold": 50,
		"damage": 5,
		"color": Color(0.8, 0.1, 0.8)
	}
}

# VS Mode additions
var enemy_send_costs = {
	GameEnums.EnemyType.BASIC: 50,
	GameEnums.EnemyType.FAST: 75,
	GameEnums.EnemyType.TANK: 125,
	GameEnums.EnemyType.BOSS: 300
}

var enemy_income_bonuses = {
	GameEnums.EnemyType.BASIC: 1,
	GameEnums.EnemyType.FAST: 2,
	GameEnums.EnemyType.TANK: 3,
	GameEnums.EnemyType.BOSS: 5
}

@onready var game_manager: Node = get_node("/root/Main/GameManager")

func _ready():
	# Initialize enemy manager
	print("[EnemyManager] Initialized")

func _process(delta):
	if wave_in_progress:
		handle_wave_spawning(delta)

func start_next_wave():
	if wave_in_progress:
		return
	
	current_wave_number += 1
	current_wave = Wave.new(current_wave_number)
  
	# Calculate total enemies in wave
	enemies_remaining = 0
	for enemy_group in current_wave.enemies:
		enemies_remaining += enemy_group.count
  
	enemies_alive = enemies_remaining
	current_enemy_index = 0
	current_enemy_type_index = 0
	wave_in_progress = true
	spawn_timer = 0.0
  
	print("[EnemyManager] Wave ", current_wave_number, " started! Enemies: ", enemies_remaining)
	emit_signal("wave_started", current_wave_number)

func handle_wave_spawning(delta):
	if enemies_remaining <= 0:
		return
	
	spawn_timer += delta
	if spawn_timer >= current_wave.spawn_delay:
		spawn_timer = 0.0
		spawn_next_enemy()

func spawn_next_enemy():
	if enemies_remaining <= 0:
		return
	
	var current_enemy_group = current_wave.enemies[current_enemy_type_index]
	
	# Spawn enemy with wave-scaled stats
	var enemy = create_enemy(
		current_enemy_group.type,
		current_enemy_group.health_multiplier
	)
	
	# For endless mode, use the center lane
	enemy.path_points.clear()
	enemy.path_points.append(Vector3(0, 0.5, -10))  # Center lane start
	enemy.path_points.append(Vector3(0, 0.5, 10))   # Center lane end
	enemy.position = enemy.path_points[0]
	enemy.current_point_index = 0
	enemy.path_progress = 0.0
	
	current_enemy_index += 1
	enemies_remaining -= 1
	
	# Move to next enemy type if current type is depleted
	if current_enemy_index >= current_enemy_group.count:
		current_enemy_index = 0
		current_enemy_type_index += 1
	
	# Check if wave is complete
	if enemies_remaining <= 0:
		wave_in_progress = false
		emit_signal("wave_completed", current_wave_number)
		game_manager.add_gold(current_wave.gold_reward)

func create_enemy(type: int, health_multiplier: float) -> Enemy:
	var enemy = enemy_scene.instantiate() as Enemy
  
	# Get base stats from enemy_data
	var base_stats = enemy_data[type]
  
	# Apply wave scaling
	enemy.enemy_name = base_stats["name"]
	enemy.max_health = base_stats["health"] * health_multiplier
	enemy.current_health = enemy.max_health
	enemy.movement_speed = base_stats["speed"]
	enemy.gold_value = base_stats["gold"]
	enemy.damage_to_base = base_stats["damage"]
  
	# Set enemy color
	enemy.enemy_color = base_stats["color"]
  
	# Connect signals
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.enemy_reached_end.connect(_on_enemy_reached_end)
  
	add_child(enemy)
	print("[EnemyManager] Enemy spawned: ", enemy.enemy_name, " Health: ", enemy.current_health)
	return enemy

func _on_enemy_died(enemy: Enemy):
	enemies_alive -= 1
	game_manager.add_gold(enemy.gold_value)
	print("[EnemyManager] Enemy died, gold value: ", enemy.gold_value)
	check_wave_status()

func _on_enemy_reached_end(enemy: Enemy):
	enemies_alive -= 1
	print("[EnemyManager] Enemy reached end! Lost ", enemy.damage_to_base, " lives")
	if enemy.target_player:
		game_manager.take_base_damage(enemy.damage_to_base)
	else:
		game_manager.take_ai_base_damage(enemy.damage_to_base)
	check_wave_status()

func check_wave_status():
	if enemies_alive <= 0 && enemies_remaining <= 0:
		wave_in_progress = false
		emit_signal("wave_completed", current_wave_number)

# VS Mode additions
func get_enemy_send_cost(type: int) -> int:
	return enemy_send_costs[type]
  
func get_enemy_income_bonus(type: int) -> int:
	return enemy_income_bonuses[type]

func send_enemy_to_player(type: int) -> void:
	# Create and add enemy to AI's lane targeting player
	var enemy = create_enemy(type, 1.0)
	enemy.target_player = true  # This enemy targets player base
	
	# Set path for AI mob lane to player - AI sends enemies on lane -3 to attack player
	enemy.path_points.clear()
	enemy.path_points.append(Vector3(-3, 0.5, -10))  # Player mob lane start (x=-3)
	enemy.path_points.append(Vector3(-3, 0.5, 10))   # Player base position
	
	# Position at start of path - using exact grid position
	enemy.position = enemy.path_points[0]
	enemy.current_point_index = 0
	enemy.path_progress = 0.0
	
	print("[EnemyManager] AI sent enemy to player: ", enemy.enemy_name, " - Lane position: ", enemy.position)

func send_enemy_to_ai(type: int) -> void:
	# Player sends enemy to AI
	var enemy = create_enemy(type, 1.0)
	enemy.target_player = false  # This enemy targets AI base
	
	# Set path for player mob lane to AI - Player sends enemies on lane 3 to attack AI
	enemy.path_points.clear()
	enemy.path_points.append(Vector3(3, 0.5, -10))  # AI mob lane start (x=3)
	enemy.path_points.append(Vector3(3, 0.5, 10))   # AI base position
	
	# Position at start of path - using exact grid position
	enemy.position = enemy.path_points[0]
	enemy.current_point_index = 0
	enemy.path_progress = 0.0
	
	print("[EnemyManager] Player sent enemy to AI: ", enemy.enemy_name, " - Lane position: ", enemy.position)
	
	# Increase player income
	game_manager.add_income_value(get_enemy_income_bonus(type))
