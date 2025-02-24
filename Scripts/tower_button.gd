# tower_button.gd
extends Button

var tower_type: int
var cost: int

func _ready():
	custom_minimum_size = Vector2(100, 100)
	text = "%s\n%d gold" % [text, cost]
