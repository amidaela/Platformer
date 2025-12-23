# bee.gd (ranged enemy)
extends CharacterBody2D

@export var health = 40
@export var damage = 8
@export var move_speed = 80
@export var detection_range = 400
@export var attack_range = 200
@export var attack_cooldown = 2.0
@export var projectile_scene: PackedScene
@export var wait_on_ground = 1.0  # seconds to wait before die()
var phase_shift = randi()*2

var player = null
var can_attack = true
var is_disabled = false
var gravity = 900

var attack_buffer = 70  
var buzz_strength = 80  # how much wiggle left/right
var buzz_speed = 3.0    # how fast wiggle happens


signal died

func _ready():
	set_physics_process(false)
	$ProgressBar.value = health
	while true:
		if Input.is_anything_pressed():
			break
		$AnimatedSprite2D.play("idle_left")
		await get_tree().process_frame
	
	add_to_group("enemies")
	
	set_physics_process(true)
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_disabled:
		velocity.x = 0
		velocity.y += gravity * delta
		move_and_slide()

		if is_on_floor() or position.y > 320:
			$ProgressBar.value = 0
			await get_tree().create_timer(wait_on_ground).timeout
			die()
		return
		
	$ProgressBar.value = health
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return 
	
	var distance_to_player = global_position.distance_to(player.global_position)
		
	if player == null:
		$AnimatedSprite2D.play("idle_left")
		move_and_slide()
		return
	
	if distance_to_player <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed

		if distance_to_player > attack_range + attack_buffer:
			# too far - move closer
			velocity.x = direction.x * move_speed
		elif distance_to_player < attack_range - attack_buffer:
			# too close - back off
			velocity.x = -direction.x * move_speed * 0.5
		else:
			velocity.x = sin((Time.get_ticks_msec() / 1000.0 * buzz_speed)-phase_shift) * buzz_strength
			velocity.y = cos(((Time.get_ticks_msec() / 1000.0 * (buzz_speed * 0.8)))-phase_shift) * buzz_strength * 2
		 
		
		# animation
		if velocity.x > 0:
			$AnimatedSprite2D.play("idle_left")
		else:
			$AnimatedSprite2D.play("right")

		if distance_to_player <= attack_range and can_attack:
			attack()
	else:
		velocity.x = 0
		$AnimatedSprite2D.play("idle_left")
		
	# boundaries
	position.x = max(0, position.x)
	position.x = min(640, position.x)
	position.y = max(0, position.y)
	position.y = min(320, position.y)
	
	move_and_slide()

func attack():
	if can_attack and player != null and projectile_scene != null:
		can_attack = false

		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position

		var direction = (player.global_position - global_position).normalized()
		projectile.setup(direction)
		var adjusted_attack_cooldown = attack_cooldown * GlobalStats.get_enemy_cooldown_multiplier()
		await get_tree().create_timer(adjusted_attack_cooldown).timeout
		can_attack = true

func take_damage(damage_amount):
	health -= damage_amount
	
	if health <= 0:
		die()

func die():
	died.emit()
	queue_free()

func disable(_duration):
	if is_disabled:
		return
	is_disabled = true

	if $AnimatedSprite2D.animation == "idle_left":
		$AnimatedSprite2D.play("web_left")
	else:
		$AnimatedSprite2D.play("web_right")
