extends Area2D

var in_water = false

signal water_state_changed(in_water: bool)

func _on_body_entered(_body):
	if in_water == false:
		in_water = true
		emit_signal("water_state_changed", true)


func _on_body_exited(_body):
	if in_water:
		in_water = false
		emit_signal("water_state_changed", false)
