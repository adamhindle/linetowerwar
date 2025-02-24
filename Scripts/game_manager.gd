# game_manager.gd
extends Node

signal gold_changed(new_amount: int)
signal income_changed(new_amount: int)
signal base_health_changed(new_amount: int, damage_taken: int)
signal ai_base_health_changed(new_amount: int, damage_taken: int)
signal game_over()
signal ai_game_over()

var gold: int = 500
var income: int = 10
var base_health: int = 100  # Starting base health
var ai_base_health: int = 100  # AI base health for VS mode
var income_interval: float = 10.0  # Seconds between income ticks
var income_timer: float = 0.0
var player_lane: MeshInstance3D = null
var ai_lane: MeshInstance3D = null

# Track game mode
var is_vs_mode: bool = false

func _ready():
	base_health_changed.emit(base_health, 0)  # Initial health display
	ai_base_health_changed.emit(ai_base_health, 0)  # Initial AI health display

func _process(delta):
	income_timer += delta
	if income_timer >= income_interval:
		add_income()
		income_timer = 0.0

func add_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)

func remove_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func add_income():
	add_gold(income)

func add_income_value(value: int):
	income += value
	income_changed.emit(income)

func set_income(new_income: int):
	income = new_income
	income_changed.emit(income)

func can_afford(amount: int) -> bool:
	return gold >= amount

func take_base_damage(damage: int):
	var previous_health = base_health
	base_health = max(0, base_health - damage)
	base_health_changed.emit(base_health, damage)
	print("[GameManager] Base took %d damage. Health: %d" % [damage, base_health])
  
	if base_health <= 0:
		trigger_game_over()

func take_ai_base_damage(damage: int):
	var previous_health = ai_base_health
	ai_base_health = max(0, ai_base_health - damage)
	ai_base_health_changed.emit(ai_base_health, damage)
	print("[GameManager] AI Base took %d damage. Health: %d" % [damage, ai_base_health])
  
	if ai_base_health <= 0:
		trigger_ai_game_over()

func trigger_game_over():
	print("[GameManager] Game Over!")
	game_over.emit()
  # You can add game over logic here, like pausing the game
	get_tree().paused = true

func trigger_ai_game_over():
	print("[GameManager] Player Victory!")
	ai_game_over.emit()
  # Handle player victory
	get_tree().paused = true

func set_vs_mode(enabled: bool):
	is_vs_mode = enabled
  
  # Reset health values when changing modes
	if is_vs_mode:
		base_health = 100
		ai_base_health = 100
		base_health_changed.emit(base_health, 0)
		ai_base_health_changed.emit(ai_base_health, 0)

func reset_game():
  # Reset all values to starting values
	gold = 500
	income = 10
	base_health = 100
	ai_base_health = 100
	income_timer = 0.0
  
  # Emit signals to update UI
	gold_changed.emit(gold)
	income_changed.emit(income)
	base_health_changed.emit(base_health, 0)
	ai_base_health_changed.emit(ai_base_health, 0)
  
  # Unpause the game
	get_tree().paused = false
