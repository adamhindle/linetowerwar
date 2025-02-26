# game_mode_manager.gd
extends Node

enum GameMode {
	ENDLESS_WAVES,
	VS_PLAYER,
	VS_AI
}

signal game_mode_changed(new_mode: int)

var current_mode: int = GameMode.ENDLESS_WAVES
var player_lane: Node
var opponent_lane: Node

# References to necessary managers
var grid_manager: Node
var game_manager: Node
var ai_manager: Node
var enemy_manager: Node
var ui: Control

func _ready():
	# Initialize game mode manager
	print("[GameModeManager] Initializing...")
	
	# Wait a moment before getting references to ensure all nodes are ready
	call_deferred("initialize_references")

func initialize_references():
	# Get necessary references
	grid_manager = get_node_or_null("/root/Main/GridManager")
	game_manager = get_node_or_null("/root/Main/GameManager") 
	ai_manager = get_node_or_null("/root/Main/AIManager")
	enemy_manager = get_node_or_null("/root/Main/EnemyManager")
	ui = get_node_or_null("/root/Main/UI")
	
	print("[GameModeManager] References initialized:")
	print("- Grid Manager: ", "Found" if grid_manager else "Not found")
	print("- Game Manager: ", "Found" if game_manager else "Not found")
	print("- AI Manager: ", "Found" if ai_manager else "Not found")
	print("- Enemy Manager: ", "Found" if enemy_manager else "Not found")
	print("- UI: ", "Found" if ui else "Not found")
	
	# Try to ensure AI Manager exists
	if not ai_manager:
		print("[GameModeManager] AI Manager not found, trying to create one...")
		var ai_manager_script = load("res://Scripts/ai_manager.gd")
		if ai_manager_script:
			ai_manager = ai_manager_script.new()
			ai_manager.name = "AIManager"
			get_node("/root/Main").add_child(ai_manager)
			print("[GameModeManager] Created new AI Manager")
		else:
			print("[GameModeManager] ERROR: Couldn't load ai_manager.gd script!")

func set_game_mode(mode: int):
	# Clear existing game state
	clear_game_state()
	
	current_mode = mode
	game_mode_changed.emit(current_mode)
	
	print("[GameModeManager] Setting game mode to: ", get_mode_name(mode))
	
	# Configure game based on mode
	match current_mode:
		GameMode.ENDLESS_WAVES:
			setup_endless_mode()
		GameMode.VS_PLAYER:
			setup_vs_player_mode()
		GameMode.VS_AI:
			setup_vs_ai_mode()

func clear_game_state():
	# Stop AI in all cases first, but check for null
	if ai_manager:
		ai_manager.stop_ai()
	else:
		print("[GameModeManager] WARNING: AI Manager is null, cannot stop AI")
	
	# Clear existing towers
	var towers = get_tree().get_nodes_in_group("towers")
	for tower in towers:
		tower.queue_free()
	
	# Clear existing enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	
	# Reset occupied positions
	if grid_manager:
		grid_manager.occupied_positions.clear()
		grid_manager.player_occupied_positions.clear()
		grid_manager.ai_occupied_positions.clear()
	
	print("[GameModeManager] Game state cleared")

func setup_endless_mode():
	# Setup endless mode
	if game_manager:
		game_manager.set_vs_mode(false)
		game_manager.reset_game()
	
	print("[GameModeManager] Setting up Endless mode lanes")
	
	# Setup center lane for endless mode
	var main_scene = get_node("/root/Main")
	
	# Show center lane, hide VS lanes
	if main_scene.has_node("Lane"):
		main_scene.get_node("Lane").visible = true
	
	var existing_vs_lanes = get_tree().get_nodes_in_group("lanes")
	for lane in existing_vs_lanes:
		lane.visible = false
	
	# Show build areas
	if main_scene.has_node("BuildArea_Left"):
		main_scene.get_node("BuildArea_Left").visible = true
	if main_scene.has_node("BuildArea_Right"):
		main_scene.get_node("BuildArea_Right").visible = true
	
	# Show endless mode UI
	if ui:
		ui.toggle_vs_mode_ui(false)
	
	print("[GameModeManager] Endless mode setup complete")

func setup_vs_player_mode():
	# Setup VS player mode
	print("[GameModeManager] Setting up VS Player mode")
	
	if game_manager:
		game_manager.set_vs_mode(true)
		game_manager.reset_game()
	
	# Setup shared VS mode elements
	setup_vs_mode_common()
	
	# Enable VS mode UI for player vs player
	if ui:
		ui.toggle_vs_mode_ui(true)
	
	print("[GameModeManager] VS Player mode setup complete")

func setup_vs_ai_mode():
	# Setup VS AI mode
	print("[GameModeManager] Setting up VS AI mode")
	
	if game_manager:
		game_manager.set_vs_mode(true)
		game_manager.reset_game()
	
	# Setup shared VS mode elements
	setup_vs_mode_common()
	
	# Start AI logic
	if ai_manager:
		ai_manager.start_ai()
	else:
		print("[GameModeManager] ERROR: AI Manager is null, cannot start AI")
	
	# Enable VS mode UI
	if ui:
		ui.toggle_vs_mode_ui(true)
	
	print("[GameModeManager] VS AI mode setup complete")

func setup_vs_mode_common():
	# Hide endless mode elements
	var main_scene = get_node("/root/Main")
	if main_scene.has_node("Lane"):
		main_scene.get_node("Lane").visible = false
	if main_scene.has_node("BuildArea_Left"):
		main_scene.get_node("BuildArea_Left").visible = false
	if main_scene.has_node("BuildArea_Right"):
		main_scene.get_node("BuildArea_Right").visible = false
	
	# Setup lanes for VS mode
	if grid_manager:
		grid_manager.setup_vs_lanes()
	else:
		print("[GameModeManager] ERROR: Grid Manager is null, cannot set up lanes")
	
	print("[GameModeManager] Common VS mode setup complete")

func toggle_vs_mode_ui(enabled: bool):
	if ui:
		ui.toggle_vs_mode_ui(enabled)
	
	# Reset game manager state for VS mode
	if game_manager:
		game_manager.reset_game()
		game_manager.set_vs_mode(enabled)

func get_mode_name(mode: int) -> String:
	match mode:
		GameMode.ENDLESS_WAVES:
			return "Endless Waves"
		GameMode.VS_PLAYER:
			return "VS Player"
		GameMode.VS_AI:
			return "VS AI"
		_:
			return "Unknown"
