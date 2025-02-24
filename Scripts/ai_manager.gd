# ai_manager.gd
extends Node

var difficulty: float = 1.0
var decision_timer: float = 0
var decision_interval: float = 3.0

var enemy_manager: Node
var game_manager: Node
var tower_manager: Node
var grid_manager: Node

var ai_gold: int = 500
var ai_income: int = 10

func _ready():
	# Initialize AI manager
	enemy_manager = get_node("/root/Main/EnemyManager")
	game_manager = get_node("/root/Main/GameManager")
	tower_manager = get_node("/root/Main/TowerManager")
	grid_manager = get_node("/root/Main/GridManager")
	
	# Don't start AI automatically
	set_process(false)

func start_ai():
	# Reset AI resources
	ai_gold = 500
	ai_income = 10
	set_process(true)
	print("AI manager started")
  
func stop_ai():
	set_process(false)
	print("AI manager stopped")

func _process(delta):
  # Add AI income over time
	add_ai_income(delta)
  
  # Make AI decisions periodically
	decision_timer += delta
	if decision_timer >= decision_interval:
		decision_timer = 0
		make_ai_decision()

func add_ai_income(delta):
	var income_interval = 10.0
	ai_gold += ai_income * (delta / income_interval)

func make_ai_decision():
  # AI decides whether to build towers or send enemies
  
  # Get AI state information
	var player_tower_count = get_player_tower_count()
	var ai_tower_count = get_ai_tower_count()
	var player_base_health = game_manager.base_health
	var ai_base_health = game_manager.ai_base_health
  
  # Decision probabilities based on game state
	var build_probability = 0.6 # Base probability to build
  
  # Adjust based on tower count - if player has more towers, build more
	if player_tower_count > ai_tower_count:
		build_probability += 0.2
  
  # Adjust based on health - if AI is low on health, build more defense
	if ai_base_health < 50:
		build_probability += 0.2
  
  # Make decision
	if randf() < build_probability:
		build_ai_tower()
	else:
		send_ai_enemies()

func build_ai_tower():
  # Logic to select tower type and position
	var affordable_towers = get_affordable_towers()
  
	if affordable_towers.is_empty():
		return
	
  # Choose a random affordable tower
	var tower_type = affordable_towers[randi() % affordable_towers.size()]
	var tower_cost = tower_manager.get_tower_cost(tower_type)
  
  # Find valid position
	var grid_positions = get_ai_grid_positions()
	if grid_positions.is_empty():
		return
	
	var position = grid_positions[randi() % grid_positions.size()]
  
  # Build tower
	ai_gold -= tower_cost
	grid_manager.create_ai_tower(position, tower_type)

func send_ai_enemies():
  # Check if AI can afford to send enemies
	var enemy_types = [
		GameEnums.EnemyType.BASIC,
		GameEnums.EnemyType.FAST,
		GameEnums.EnemyType.TANK
	]
  
  # Filter affordable enemy types
	var affordable_enemies = []
	for type in enemy_types:
		var cost = enemy_manager.get_enemy_send_cost(type)
		if ai_gold >= cost:
			affordable_enemies.append(type)
  
	if affordable_enemies.is_empty():
		return
	
  # Choose random enemy type to send
	var enemy_type = affordable_enemies[randi() % affordable_enemies.size()]
	var cost = enemy_manager.get_enemy_send_cost(enemy_type)
  
  # Send enemy to player
	ai_gold -= cost
	enemy_manager.send_enemy_to_player(enemy_type)
  
  # Increase AI income
	ai_income += enemy_manager.get_enemy_income_bonus(enemy_type)

func get_affordable_towers() -> Array:
	var affordable = []
	for type in tower_manager.TowerType.values():
		if ai_gold >= tower_manager.get_tower_cost(type):
			affordable.append(type)
	return affordable

func get_ai_grid_positions() -> Array:
  # Get available positions on AI's side
	return grid_manager.get_available_positions("ai")

func get_player_tower_count() -> int:
	return grid_manager.get_tower_count("player")

func get_ai_tower_count() -> int:
	return grid_manager.get_tower_count("ai")
