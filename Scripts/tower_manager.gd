# tower_manager.gd
extends Node

enum TowerType {
	BASIC,
	ARCHER,
	CANNON,
	FROST
}

var tower_scene = preload("res://Scenes/tower.tscn")
var grid_manager: Node
var selected_tower_type: TowerType = TowerType.BASIC

var tower_data = {
	TowerType.BASIC: {
		"name": "Basic Tower",
		"cost": 100,
		"damage": 10.0,
		"attack_speed": 1.0,
		"attack_range": 5.0,
		"color": Color(0.8, 0.2, 0.2)  # Red
	},
	TowerType.ARCHER: {
		"name": "Archer Tower",
		"cost": 150,
		"damage": 15.0,
		"attack_speed": 1.5,
		"attack_range": 6.0,
		"color": Color(0.2, 0.8, 0.2)  # Green
	},
	TowerType.CANNON: {
		"name": "Cannon Tower",
		"cost": 200,
		"damage": 25.0,
		"attack_speed": 0.8,
		"attack_range": 4.0,
		"color": Color(0.2, 0.2, 0.8)  # Blue
	},
	TowerType.FROST: {
		"name": "Frost Tower",
		"cost": 175,
		"damage": 8.0,
		"attack_speed": 1.0,
		"attack_range": 4.5,
		"color": Color(0.2, 0.8, 0.8)  # Cyan
	}
}

func _ready():
	grid_manager = get_node("/root/Main/GridManager")

func create_tower(type: TowerType) -> Tower:
	var tower = tower_scene.instantiate() as Tower
	
	# Apply tower type specific stats
	var stats = tower_data[type]
	tower.tower_name = stats["name"]
	tower.damage = stats["damage"]
	tower.attack_speed = stats["attack_speed"]
	tower.attack_range = stats["attack_range"]
	tower.cost = stats["cost"]
	tower.tower_color = stats["color"]
	
	# Set projectile type based on tower type
	match type:
		TowerType.ARCHER:
			tower.projectile_type = Tower.ProjectileType.ARROW
		TowerType.CANNON:
			tower.projectile_type = Tower.ProjectileType.CANNONBALL
		TowerType.FROST:
			tower.projectile_type = Tower.ProjectileType.MAGIC
		_:
			tower.projectile_type = Tower.ProjectileType.ARROW
	
	return tower

func get_tower_cost(type: TowerType) -> int:
	return tower_data[type]["cost"]

func set_selected_tower(type: TowerType):
	selected_tower_type = type
	grid_manager.enter_build_mode(type)

func get_selected_tower_type() -> TowerType:
	return selected_tower_type
