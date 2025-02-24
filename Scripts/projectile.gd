# projectile.gd
extends Node3D

var target: Node3D
var damage: float = 10.0
var speed: float = 30.0  # Increased base speed
var tower: Node3D

func _process(delta):
	if !is_instance_valid(target):
		queue_free()
		return
		
	# Move towards target
	var direction = (target.global_position - global_position)
	if direction.length() < speed * delta:
		# Hit target
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
	else:
		global_translate(direction.normalized() * speed * delta)
		
		# Make projectile face movement direction
		look_at(target.global_position)
