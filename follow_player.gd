extends "res://steering.gd"



func _ready():
	# Initialization here
	max_acceleration = 1
	max_velocity = 20.0
	target = get_parent().get_node("character")


	set_fixed_process(true)
	pass

func _fixed_process(delta):
	reset_steering()
	arrive()
	_steering_fixed_process(delta)