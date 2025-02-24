# wave.gd
class_name Wave

var wave_number: int
var enemies: Array[Dictionary] = []
var spawn_delay: float = 1.0  # Time between enemy spawns
var is_boss_wave: bool = false
var gold_reward: int = 0

func _init(number: int):
	wave_number = number
	setup_wave()

func setup_wave():
	# Base difficulty scaling
	var difficulty_multiplier = 1.0 + (wave_number - 1) * 0.2
	
	# Every 5th wave is a boss wave
	is_boss_wave = wave_number % 5 == 0
	
	if is_boss_wave:
		enemies.append({
			"type": GameEnums.EnemyType.BOSS,
			"count": 1,
			"health_multiplier": difficulty_multiplier * 2.0
		})
		gold_reward = 100 * wave_number
	else:
		# Regular wave composition
		enemies.append({
			"type": GameEnums.EnemyType.BASIC,
			"count": 5 + wave_number,
			"health_multiplier": difficulty_multiplier
		})
		
		if wave_number >= 3:
			enemies.append({
				"type": GameEnums.EnemyType.FAST,
				"count": wave_number - 2,
				"health_multiplier": difficulty_multiplier
			})
			
		if wave_number >= 5:
			enemies.append({
				"type": GameEnums.EnemyType.TANK,
				"count": floor(wave_number / 2),
				"health_multiplier": difficulty_multiplier
			})
		
		gold_reward = 50 * wave_number
