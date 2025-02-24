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

func _ready():
	# Initialize game mode manager
	pass

func set_game_mode(mode: int):
	current_mode = mode
	game_mode_changed.emit(current_mode)
	
	# Get necessary references
	var grid_manager = get_node("/root/Main/GridManager")
	var game_manager = get_node("/root/Main/GameManager") 
	var ai_manager = get_node("/root/Main/AIManager")
	var main_scene = get_node("/root/Main")
	
	# Stop AI in all cases first
	ai_manager.stop_ai()
	
	# Configure game based on mode
	match current_mode:
		GameMode.ENDLESS_WAVES:
			# Setup endless mode
			game_manager.set_vs_mode(false)
			game_manager.reset_game()
			
			# Show center lane, hide VS lanes
			main_scene.get_node("Lane").visible = true
			var existing_vs_lanes = get_tree().get_nodes_in_group("lanes")
			for lane in existing_vs_lanes:
				lane.visible = false
			
			# Show build areas
			main_scene.get_node("BuildArea_Left").visible = true
			main_scene.get_node("BuildArea_Right").visible = true
		
		GameMode.VS_PLAYER:
			# Setup VS player mode
			game_manager.set_vs_mode(true)
			game_manager.reset_game()
			
			# Hide center lane, show VS lanes
			main_scene.get_node("Lane").visible = false
			main_scene.get_node("BuildArea_Left").visible = false
			main_scene.get_node("BuildArea_Right").visible = false
			
			# Setup VS lanes
			grid_manager.setup_vs_lanes()
			
			# Enable VS mode UI
			toggle_vs_mode_ui(true)
		
		GameMode.VS_AI:
			# Setup VS AI mode
			game_manager.set_vs_mode(true)
			game_manager.reset_game()
			
			# Hide center lane, show VS lanes
			main_scene.get_node("Lane").visible = false
			main_scene.get_node("BuildArea_Left").visible = false
			main_scene.get_node("BuildArea_Right").visible = false
			
			# Setup VS lanes
			grid_manager.setup_vs_lanes()
			
			# Start AI logic
			ai_manager.start_ai()
			
			# Enable VS mode UI
			toggle_vs_mode_ui(true)

func setup_endless_mode():
	# Current default mode - use existing setup
	pass

func setup_vs_player_mode():
	# Set up two lanes for players
	setup_multiplayer_lanes()
	# Disable wave buttons, enable send enemy buttons
	toggle_vs_mode_ui(true)

func setup_vs_ai_mode():
	# Set up player and AI lanes
	setup_multiplayer_lanes()
	# Start AI logic
	get_node("/root/Main/AIManager").start_ai()
	# Enable VS mode UI
	toggle_vs_mode_ui(true)

func setup_multiplayer_lanes():
	# Let grid manager handle lane creation
	var grid_manager = get_node("/root/Main/GridManager")
	if grid_manager:
		grid_manager.setup_vs_lanes()

func toggle_vs_mode_ui(enabled: bool):
	var ui = get_node("/root/Main/UI")
	ui.toggle_vs_mode_ui(enabled)
	
	# Reset game manager state for VS mode
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		game_manager.reset_game()
		game_manager.set_vs_mode(enabled)
