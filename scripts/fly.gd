extends Area2D
@export var health_value = 10  # health gained when collected

func _process(_delta):
	$AnimatedSprite2D.play("default")

func _ready():
	# Connect the area_entered signal
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area):
	if area.is_in_group("player"):
		var player = area.get_parent()
		if player.has_method("add_health"):
			player.add_health(10)
		queue_free()
