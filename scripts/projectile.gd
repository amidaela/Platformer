# projectile.gd
extends Area2D

@export var speed = 400
@export var damage = 10
@export var Gravity = 800.0 
var velocity = Vector2.ZERO
var lifetime = 2.0

func _ready():
	collision_mask = 1
	body_entered.connect(_on_body_entered)

	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup(shoot_direction: Vector2):
	var upward_boost = Vector2(0, -0.3)
	velocity = (shoot_direction.normalized() + upward_boost).normalized() * speed
	rotation = velocity.angle()

func _physics_process(delta):
	velocity.y += Gravity * delta
	position += velocity * delta

	if velocity.length() > 0:
		rotation = velocity.angle()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
	if body.is_in_group("terrain"):
		queue_free()
