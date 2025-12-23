extends Area2D

@export var speed = 300
@export var disable_time = 2.0  # how long enemy is disabled
var direction = Vector2.ZERO
var lifetime = 0.1  # web starts to disappear

func _ready():

	$Sprite2D.play("decay")
	await get_tree().create_timer(0.5).timeout
	queue_free()

func setup(shoot_direction: Vector2):
	direction = shoot_direction.normalized()
	rotation = direction.angle()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		return
	if body.is_in_group("enemies"):
		var adjusted_disable_time = disable_time * GlobalStats.get_disable_multiplier()
		body.disable(adjusted_disable_time)
	queue_free()
