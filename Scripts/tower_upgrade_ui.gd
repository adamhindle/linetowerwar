# tower_upgrade_ui.gd
extends Panel

var current_tower: Tower = null
var game_manager: Node

@onready var tower_name_label = $VBoxContainer/TowerName
@onready var level_label = $VBoxContainer/Level
@onready var damage_label = $VBoxContainer/Stats/Damage
@onready var attack_speed_label = $VBoxContainer/Stats/AttackSpeed
@onready var range_label = $VBoxContainer/Stats/Range
@onready var upgrade_button = $VBoxContainer/UpgradeButton
@onready var sell_button = $VBoxContainer/SellButton
@onready var close_button = $VBoxContainer/CloseButton

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func show_for_tower(object):
	# Handle test cube case
	if object.get_name().begins_with("StaticBody"):
		tower_name_label.text = "Test Cube"
		level_label.text = "Level: 1"
		damage_label.text = "Test Cube Stats"
		attack_speed_label.visible = false
		range_label.visible = false
		upgrade_button.visible = false
		sell_button.visible = false
		position = get_viewport().get_mouse_position()
		# Ensure the panel stays within viewport bounds
		position.x = clamp(position.x, 0, get_viewport().size.x - size.x)
		position.y = clamp(position.y, 0, get_viewport().size.y - size.y)
		visible = true
		return

	# Handle tower case
	current_tower = object
	update_display()
	position = get_viewport().get_mouse_position()
	# Ensure the panel stays within viewport bounds
	position.x = clamp(position.x, 0, get_viewport().size.x - size.x)
	position.y = clamp(position.y, 0, get_viewport().size.y - size.y)
	visible = true

func update_display():
	if !current_tower:
		return
		
	tower_name_label.text = current_tower.tower_name
	level_label.text = "Level: %d" % current_tower.tower_level
	damage_label.text = "Damage: %.1f" % current_tower.damage
	attack_speed_label.text = "Attack Speed: %.1f" % current_tower.attack_speed
	range_label.text = "Range: %.1f" % current_tower.attack_range
	
	var upgrade_cost = current_tower.get_upgrade_cost()
	upgrade_button.text = "Upgrade (%d gold)" % upgrade_cost
	upgrade_button.disabled = !game_manager.can_afford(upgrade_cost)
	
	var sell_value = current_tower.get_sell_value()
	sell_button.text = "Sell (%d gold)" % sell_value

	# Show all tower-specific elements
	attack_speed_label.visible = true
	range_label.visible = true
	upgrade_button.visible = true
	sell_button.visible = true

func _on_upgrade_pressed():
	if !current_tower:
		return
		
	var upgrade_cost = current_tower.get_upgrade_cost()
	if game_manager.can_afford(upgrade_cost):
		game_manager.remove_gold(upgrade_cost)
		current_tower.upgrade()
		update_display()

func _on_sell_pressed():
	if !current_tower:
		return
		
	var sell_value = current_tower.get_sell_value()
	game_manager.add_gold(sell_value)
	current_tower.queue_free()
	visible = false

func _on_close_pressed():
	visible = false
