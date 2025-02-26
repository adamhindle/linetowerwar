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
var ai_income: int = 1
var is_active: bool = false

# Startup cooldown
var startup_cooldown_time: float = 30.0  # 30 seconds startup cooldown
var startup_cooldown_active: bool = true
var startup_cooldown_timer: float = 0.0

func _ready():
	# Initialize AI manager
	print("[AIManager] Initializing...")
	enemy_manager = get_node("/root/Main/EnemyManager")
	game_manager = get_node("/root/Main/GameManager")
	tower_manager = get_node("/root/Main/TowerManager")
	grid_manager = get_node("/root/Main/GridManager")
	
	# Don't start AI automatically
	set_process(false)
	print("[AIManager] Initialized, waiting to be activated")

func start_ai():
	# Reset AI resources
	ai_gold = 500
	ai_income = 1
	is_active = true
	
	# Initialize startup cooldown
	startup_cooldown_active = true
	startup_cooldown_timer = 0.0
	
	set_process(true)
	print("[AIManager] AI manager started with gold: ", ai_gold, " and income: ", ai_income)
	print("[AIManager] Startup cooldown active for ", startup_cooldown_time, " seconds")
  
func stop_ai():
	is_active = false
	set_process(false)
	print("[AIManager] AI manager stopped")

func _process(delta):
	if !is_active:
		return
	
	# Handle startup cooldown
	if startup_cooldown_active:
		startup_cooldown_timer += delta
		if startup_cooldown_timer >= startup_cooldown_time:
			startup_cooldown_active = false
			print("[AIManager] Startup cooldown complete - AI can now send enemies")
		else:
			# During startup cooldown, still add income but don't make decisions
			add_ai_income(delta)
			return
		
	# Add AI income over time
	add_ai_income(delta)
  
	# Make AI decisions periodically (only after startup cooldown)
	decision_timer += delta
	if decision_timer >= decision_interval:
		decision_timer = 0
		make_ai_decision()

func add_ai_income(delta):
	var income_interval = 1.0
	var income_delta = ai_income * (delta / income_interval)
	ai_gold += income_delta
	if int(ai_gold) % 100 == 0:
		print("[AIManager] Current gold: ", int(ai_gold), ", income: ", ai_income)

func make_ai_decision():
	# Don't make decisions during startup cooldown
	if startup_cooldown_active:
		return
		
	# AI decides whether to build towers or send enemies
	
	# Get AI state information
	var player_tower_count = get_player_tower_count()
	var ai_tower_count = get_ai_tower_count()
	var player_base_health = game_manager.base_health
	var ai_base_health = game_manager.ai_base_health
	
	print("[AIManager] Making decision - Player towers: ", player_tower_count, 
		", AI towers: ", ai_tower_count,
		", Player health: ", player_base_health,
		", AI health: ", ai_base_health)
  
	# Decision probabilities based on game state
	var build_probability = 0.6 # Base probability to build
  
	# Adjust based on tower count - if player has more towers, build more
	if player_tower_count > ai_tower_count:
		build_probability += 0.2
  
	# Adjust based on health - if AI is low on health, build more defense
	if ai_base_health < 50:
		build_probability += 0.2
  
	print("[AIManager] Build probability: ", build_probability)
  
	# Make decision
	if randf() < build_probability:
		build_ai_tower()
	else:
		send_ai_enemies()

func build_ai_tower():
	# Logic to select tower type and position
	var affordable_towers = get_affordable_towers()
	
	print("[AIManager] Available towers to build: ", affordable_towers.size())
  
	if affordable_towers.is_empty():
		print("[AIManager] No affordable towers")
		return
	
	# Choose a random affordable tower
	var tower_type = affordable_towers[randi() % affordable_towers.size()]
	var tower_cost = tower_manager.get_tower_cost(tower_type)
  
	# Find valid position
	var grid_positions = get_ai_grid_positions()
	
	print("[AIManager] Available build positions: ", grid_positions.size())
	
	if grid_positions.is_empty():
		print("[AIManager] No available build positions")
		return
	
	var position = grid_positions[randi() % grid_positions.size()]
  
	# Build tower
	ai_gold -= tower_cost
	grid_manager.create_ai_tower(position, tower_type)
	print("[AIManager] Built tower type ", tower_type, " at position ", position, ", remaining gold: ", ai_gold)

func send_ai_enemies():
	# Don't send enemies during startup cooldown
	if startup_cooldown_active:
		print("[AIManager] Cannot send enemies during startup cooldown")
		return
		
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
  
	print("[AIManager] Affordable enemies to send: ", affordable_enemies.size())
	
	if affordable_enemies.is_empty():
		print("[AIManager] No affordable enemies to send")
		return
	
	# Choose random enemy type to send
	var enemy_type = affordable_enemies[randi() % affordable_enemies.size()]
	var cost = enemy_manager.get_enemy_send_cost(enemy_type)
  
	# Send enemy to player
	ai_gold -= cost
	enemy_manager.send_enemy_to_player(enemy_type)
	
	# Increase AI income
	ai_income += enemy_manager.get_enemy_income_bonus(enemy_type)
	print("[AIManager] Sent enemy type ", enemy_type, " to player, cost: ", cost, 
		", remaining gold: ", ai_gold, ", new income: ", ai_income)

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
