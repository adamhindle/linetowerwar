# game_ui.gd
extends Control

# Panel references instead of direct control references
@onready var endless_panel = $EndlessModePanel
@onready var vs_panel = $VSModePanel
@onready var mode_selection_panel = $ModeSelectionPanel
@onready var game_over_panel = $GameOverPanel
@onready var tower_upgrade_ui = $TowerUpgradeUI

# Specific button references
@onready var next_wave_button = $EndlessModePanel/ResourcePanel/NextWaveButton

# Send enemy cooldown
var send_cooldown_timer: float = 0.0
var send_cooldown_time: float = 3.0  # 3 seconds between sends
var can_send_enemy: bool = true

var tower_button_scene = preload("res://Scenes/tower_button.tscn")
var tower_manager: Node
var game_manager: Node
var enemy_manager: Node

func _ready():
	# Get references to managers
	tower_manager = get_node("/root/Main/TowerManager")
	game_manager = get_node("/root/Main/GameManager")
	enemy_manager = get_node("/root/Main/EnemyManager")
  
	# Connect signals
	game_manager.gold_changed.connect(_on_gold_changed)
	game_manager.income_changed.connect(_on_income_changed)
	enemy_manager.wave_started.connect(_on_wave_started)
	enemy_manager.wave_completed.connect(_on_wave_completed)
  
	# Add null check for button
	if next_wave_button:
		next_wave_button.pressed.connect(_on_next_wave_pressed)
	
	game_manager.base_health_changed.connect(_on_base_health_changed)
	game_manager.ai_base_health_changed.connect(_on_ai_base_health_changed)
	game_manager.game_over.connect(_on_game_over)
  
	setup_tower_buttons()
	update_resource_display()
	setup_mode_selection()
	setup_send_enemy_buttons()
  
	# Initialize wave display
	if endless_panel:
		endless_panel.get_node("ResourcePanel/WaveLabel").text = "Wave: 0"
	
	if next_wave_button:
		next_wave_button.disabled = false
  
	# Start with mode selection visible
	mode_selection_panel.visible = true
	vs_panel.visible = false
	endless_panel.visible = false
	
	# Add cooldown label for VS mode
	var cooldown_label = Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.text = "Ready to send"
	if vs_panel and vs_panel.get_node("SendEnemiesContainer"):
		vs_panel.get_node("SendEnemiesContainer").add_child(cooldown_label)

func _process(delta):
	# Process send cooldown timer
	if !can_send_enemy:
		send_cooldown_timer += delta
		if send_cooldown_timer >= send_cooldown_time:
			send_cooldown_timer = 0.0
			can_send_enemy = true
			update_send_button_states(true)
			var cooldown_label = vs_panel.get_node_or_null("SendEnemiesContainer/CooldownLabel")
			if cooldown_label:
				cooldown_label.text = "Ready to send"
		else:
			var cooldown_label = vs_panel.get_node_or_null("SendEnemiesContainer/CooldownLabel")
			if cooldown_label:
				cooldown_label.text = "Cooldown: %.1f" % (send_cooldown_time - send_cooldown_timer)

func setup_tower_buttons():
	# Create a button for each tower type
	for type in tower_manager.TowerType.values():
		# For endless mode
		if endless_panel:
			var endless_grid = endless_panel.get_node("TowerSelection/GridContainer")
			if endless_grid:
				var button = tower_button_scene.instantiate()
				var tower_data = tower_manager.tower_data[type]
		
				button.text = tower_data["name"]
				button.tower_type = type
				button.cost = tower_data["cost"]
				button.pressed.connect(_on_tower_button_pressed.bind(type))
		
				endless_grid.add_child(button)
	
		# For VS mode
		if vs_panel:
			var vs_grid = vs_panel.get_node("TowerSelection/GridContainer")
			if vs_grid:
				var button = tower_button_scene.instantiate()
				var tower_data = tower_manager.tower_data[type]
		
				button.text = tower_data["name"]
				button.tower_type = type
				button.cost = tower_data["cost"]
				button.pressed.connect(_on_tower_button_pressed.bind(type))
		
				vs_grid.add_child(button)

func _on_tower_button_pressed(type: int):
	tower_manager.set_selected_tower(type)
	update_button_states()

func update_button_states():
	# Update endless mode buttons
	if endless_panel:
		var endless_grid = endless_panel.get_node("TowerSelection/GridContainer")
		if endless_grid:
			for button in endless_grid.get_children():
				var can_afford = game_manager.can_afford(button.cost)
				button.disabled = !can_afford
				button.modulate = Color(1, 1, 1, 1) if can_afford else Color(0.5, 0.5, 0.5, 1)
  
	# Update VS mode buttons
	if vs_panel:
		var vs_grid = vs_panel.get_node("TowerSelection/GridContainer")
		if vs_grid:
			for button in vs_grid.get_children():
				var can_afford = game_manager.can_afford(button.cost)
				button.disabled = !can_afford
				button.modulate = Color(1, 1, 1, 1) if can_afford else Color(0.5, 0.5, 0.5, 1)

func _on_gold_changed(new_amount: int):
	if endless_panel and endless_panel.visible:
		var gold_label = endless_panel.get_node("ResourcePanel/GoldLabel")
		if gold_label:
			gold_label.text = "Gold: %d" % new_amount
  
	if vs_panel and vs_panel.visible:
		var gold_label = vs_panel.get_node("ResourcePanel/GoldLabel")
		if gold_label:
			gold_label.text = "Gold: %d" % new_amount
  
	update_button_states()
	if vs_panel and vs_panel.visible:
		update_send_button_states(can_send_enemy)

func _on_income_changed(new_amount: int):
	if endless_panel and endless_panel.visible:
		var income_label = endless_panel.get_node("ResourcePanel/IncomeLabel")
		if income_label:
			income_label.text = "Income: %d/10s" % new_amount
  
	if vs_panel and vs_panel.visible:
		var income_label = vs_panel.get_node("ResourcePanel/IncomeLabel")
		if income_label:
			income_label.text = "Income: %d/10s" % new_amount

func _on_wave_started(wave_number: int):
	if endless_panel and endless_panel.visible:
		var wave_label = endless_panel.get_node("ResourcePanel/WaveLabel")
		if wave_label:
			wave_label.text = "Wave: %d" % wave_number
	
		if next_wave_button:
			next_wave_button.disabled = true
  
	print("Wave %d started!" % wave_number)

func _on_wave_completed(wave_number: int):
	if next_wave_button:
		next_wave_button.disabled = false
	print("Wave %d completed!" % wave_number)

func _on_next_wave_pressed():
	enemy_manager.start_next_wave()

func update_resource_display():
	# Update Endless Mode UI
	if endless_panel:
		var gold_label = endless_panel.get_node("ResourcePanel/GoldLabel")
		var income_label = endless_panel.get_node("ResourcePanel/IncomeLabel")
		var wave_label = endless_panel.get_node("ResourcePanel/WaveLabel")
		var base_health_label = endless_panel.get_node("ResourcePanel/BaseHealthLabel")
	
		if gold_label:
			gold_label.text = "Gold: %d" % game_manager.gold
	
		if income_label:
			income_label.text = "Income: %d/10s" % game_manager.income
	
		if wave_label and enemy_manager:
			wave_label.text = "Wave: %d" % enemy_manager.current_wave_number
	
		if base_health_label:
			base_health_label.text = "Lives: %d" % game_manager.base_health
  
	# Update VS Mode UI
	if vs_panel:
		var gold_label = vs_panel.get_node("ResourcePanel/GoldLabel")
		var income_label = vs_panel.get_node("ResourcePanel/IncomeLabel")
		var base_health_label = vs_panel.get_node("ResourcePanel/BaseHealthLabel")
		var ai_health_label = vs_panel.get_node("ResourcePanel/AIHealthLabel")
	
		if gold_label:
			gold_label.text = "Gold: %d" % game_manager.gold
	
		if income_label:
			income_label.text = "Income: %d/10s" % game_manager.income
	
		if base_health_label:
			base_health_label.text = "Lives: %d" % game_manager.base_health
	
		# Update AI health label if in VS mode
		if vs_panel.visible and ai_health_label:
			ai_health_label.text = "AI Lives: %d" % game_manager.ai_base_health
	
func _on_base_health_changed(new_health: int, damage_taken: int):
	if endless_panel and endless_panel.visible:
		var health_label = endless_panel.get_node("ResourcePanel/BaseHealthLabel")
		if health_label:
			health_label.text = "Lives: %d" % new_health
			if damage_taken > 0:
				# Optional: Add visual feedback when damage is taken
				var tween = create_tween()
				health_label.modulate = Color.RED
				tween.tween_property(health_label, "modulate", Color.WHITE, 0.5)
  
	if vs_panel and vs_panel.visible:
		var health_label = vs_panel.get_node("ResourcePanel/BaseHealthLabel")
		if health_label:
			health_label.text = "Lives: %d" % new_health
			if damage_taken > 0:
				# Optional: Add visual feedback when damage is taken
				var tween = create_tween()
				health_label.modulate = Color.RED
				tween.tween_property(health_label, "modulate", Color.WHITE, 0.5)

func _on_ai_base_health_changed(new_health: int, damage_taken: int):
	if vs_panel and vs_panel.visible:
		var health_label = vs_panel.get_node("ResourcePanel/AIHealthLabel")
		if health_label:
			health_label.text = "AI Lives: %d" % new_health
			if damage_taken > 0:
				var tween = create_tween()
				health_label.modulate = Color.RED
				tween.tween_property(health_label, "modulate", Color.WHITE, 0.5)
  
func _on_game_over():
	game_over_panel.visible = true

# VS Mode additions
func setup_mode_selection():
	var endless_button = $ModeSelectionPanel/EndlessButton
	var vs_player_button = $ModeSelectionPanel/VSPlayerButton
	var vs_ai_button = $ModeSelectionPanel/VSAIButton
  
	if endless_button:
		endless_button.pressed.connect(_on_endless_mode_selected)
  
	if vs_player_button:
		vs_player_button.pressed.connect(_on_vs_player_selected)
  
	if vs_ai_button:
		vs_ai_button.pressed.connect(_on_vs_ai_selected)

func _on_endless_mode_selected():
	var game_mode_manager = get_node("/root/Main/GameModeManager")
	if game_mode_manager:
		game_mode_manager.set_game_mode(0)  # GameModeManager.GameMode.ENDLESS_WAVES
  
	mode_selection_panel.visible = false
	endless_panel.visible = true
	vs_panel.visible = false
  
	# Tell game manager to use endless mode settings
	game_manager.set_vs_mode(false)

func _on_vs_player_selected():
	var game_mode_manager = get_node("/root/Main/GameModeManager")
	if game_mode_manager:
		game_mode_manager.set_game_mode(1)  # GameModeManager.GameMode.VS_PLAYER
  
	mode_selection_panel.visible = false
	endless_panel.visible = false
	vs_panel.visible = true
  
	# Tell game manager to use VS mode settings
	game_manager.set_vs_mode(true)

func _on_vs_ai_selected():
	var game_mode_manager = get_node("/root/Main/GameModeManager")
	if game_mode_manager:
		game_mode_manager.set_game_mode(2)  # GameModeManager.GameMode.VS_AI
  
	mode_selection_panel.visible = false
	endless_panel.visible = false
	vs_panel.visible = true
  
	# Tell game manager to use VS mode settings
	game_manager.set_vs_mode(true)

func setup_send_enemy_buttons():
	# Get the container for enemy buttons
	var send_enemies_container = vs_panel.get_node("SendEnemiesContainer")
	if !send_enemies_container:
		return
  
	# Create a button for each enemy type
	for type in GameEnums.EnemyType.values():
		var button = Button.new()
	
		if enemy_manager and enemy_manager.enemy_data.has(type):
			var enemy_data = enemy_manager.enemy_data[type]
			var cost = enemy_manager.get_enemy_send_cost(type)
	  
			button.text = "%s (%d gold)" % [enemy_data["name"], cost]
			button.custom_minimum_size = Vector2(150, 50)
			button.pressed.connect(_on_send_enemy_pressed.bind(type))
			button.set_meta("enemy_type", type)  # Store the enemy type
	  
			send_enemies_container.add_child(button)

func _on_send_enemy_pressed(type: int):
	if !enemy_manager or !can_send_enemy:
		return
	
	var cost = enemy_manager.get_enemy_send_cost(type)
  
	if game_manager.can_afford(cost):
		game_manager.remove_gold(cost)
		enemy_manager.send_enemy_to_ai(type)
		print("Sent enemy type %d to opponent" % type)
		
		# Start cooldown
		can_send_enemy = false
		send_cooldown_timer = 0.0
		update_send_button_states(false)

func update_send_button_states(enabled: bool):
	# Update the state of all send buttons
	var send_enemies_container = vs_panel.get_node_or_null("SendEnemiesContainer")
	if !send_enemies_container:
		return
	
	for button in send_enemies_container.get_children():
		if button is Button:
			# Don't disable buttons if they're the header or label
			if button.name != "EnemySelectionHeader" and button.name != "CooldownLabel":
				var type = button.get_meta("enemy_type") if button.has_meta("enemy_type") else -1
				if type != -1:
					var can_afford = game_manager.can_afford(enemy_manager.get_enemy_send_cost(type))
					button.disabled = !enabled or !can_afford
					button.modulate = Color(1, 1, 1, 1) if (enabled and can_afford) else Color(0.5, 0.5, 0.5, 1)

func toggle_vs_mode_ui(enabled: bool):
	vs_panel.visible = enabled
	endless_panel.visible = !enabled
	
	# Reset cooldown when toggling UI
	can_send_enemy = true
	send_cooldown_timer = 0.0
	
	if vs_panel.visible:
		var cooldown_label = vs_panel.get_node_or_null("SendEnemiesContainer/CooldownLabel")
		if cooldown_label:
			cooldown_label.text = "Ready to send"
