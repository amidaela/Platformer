extends CharacterBody2D

@export var speed = 100
@export var gravity = 800.0
@export var jump_force = 400.0
@export var health = 100
@export var attack_damage = 15
@export var attack_cooldown = 0.5

@export var web_scene: PackedScene
@export var web_cooldown = 1.0
var can_shoot_web = true

var can_attack = true
var is_attacking = false
var is_hurt = false
var in_water = false

var end_reached = false
var hurt_knockback = 0
var hurt_dir = 0

signal reached_exit
signal died

func _ready():
	add_to_group("player")
	end_reached = false
	$WebCooldown.visible = false

func _physics_process(delta):
	$ProgressBar.value = health
	GlobalStats.health = health
	
	if position.x < 0:
		position.x = 1
	
	if is_hurt:
		if is_on_floor():
			velocity.y += hurt_knockback
		velocity.x += hurt_knockback * hurt_dir * 4
		hurt_knockback = 0.0
		$AnimatedSprite2D.play("hurt")
		move_and_slide()
		return
		
	if position.y > 320:
		die()
		return
	# exit check
	if position.x > 640 and !end_reached:
		reached_exit.emit()
		end_reached = true

	# gravity
	if !is_on_floor() and !in_water:
		velocity.y += gravity * delta
		if velocity.y > 1000:
			velocity.y = 1000
	elif in_water:
		velocity.y += 0.25 * gravity * delta

	# jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and !in_water:
		velocity.y = -jump_force
	elif Input.is_action_just_pressed("jump") and in_water:
		velocity.y = -jump_force * 0.3

	# movement
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	velocity.x = speed * horizontal_direction

	# animation
	if not is_attacking:
		if velocity.x > 0:
			$AnimatedSprite2D.play("walk_right")
		elif velocity.x == 0:
			$AnimatedSprite2D.play("idle")
		elif velocity.x < 0:
			$AnimatedSprite2D.play("walk_left")

	# combat input
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()
	if Input.is_action_just_pressed("attack_left") and can_attack:
		attack(Vector2.LEFT)
	if Input.is_action_just_pressed("attack_right") and can_attack:
		attack(Vector2.RIGHT)
	if Input.is_action_just_pressed("shoot") and !in_water:
		shoot_web()
		
	#boundaries
	position.y = max(0, position.y)
	
	velocity.y = max(-jump_force, velocity.y) # max cause up is negative

	move_and_slide()

func attack(dir = Vector2.ZERO):
	
	is_attacking = true
	if not can_attack:
		return

	can_attack = false

	if dir == Vector2.ZERO:
		var mouse_pos = get_global_mouse_position()
		dir = Vector2.RIGHT if mouse_pos.x > global_position.x else Vector2.LEFT

	var dash_distance = 30
	var dash_speed = 300
	var duration = dash_distance / float(dash_speed)

	var start = global_position
	var target = start + dir * dash_distance

	var tween = create_tween()
	tween.tween_method(
		func(percent):
			var desired = start.lerp(target, percent)
			var offset = desired - global_position
			var col = move_and_collide(offset)
			if col:
				tween.kill()
			else:
				global_position = desired,
		0.0, 1.0, duration
	)

	if dir == Vector2.RIGHT:
		$AnimatedSprite2D.play("attack_right")
	else:
		$AnimatedSprite2D.play("attack_left")

	
	var damage = attack_damage
	damage *= GlobalStats.get_player_attack_multiplier()
	
	var attack_area = $PlayerAttackArea
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			body.take_damage(damage)
	var cooldown = attack_cooldown * GlobalStats.get_player_cooldown_multiplier()
	await get_tree().create_timer(cooldown).timeout
	can_attack = true
	is_attacking = false

func take_damage(damage, dir=0):
	if is_hurt:
		return  # prevents stacking hits

	health -= damage
	GlobalStats.hits_taken += damage

	if health <= 0:
		die()
		return

	is_hurt = true
	hurt_knockback = -jump_force * 0.1
	hurt_dir = dir
	
	get_tree().create_timer(0.3).timeout.connect(func():
		is_hurt = false
	)

func die():
	died.emit()
	queue_free()

func shoot_web():
	if not can_shoot_web or web_scene == null:
		return

	can_shoot_web = false

	var web = web_scene.instantiate()
	get_parent().add_child(web)
	web.global_position = global_position

	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	web.setup(dir)
	$WebCooldown.visible = true
	var bar := $WebCooldown
	bar.value = bar.max_value
	var tween := create_tween()
	tween.tween_property(bar, "value", 0.0, web_cooldown)
	await tween.finished
	$WebCooldown.visible = false
	can_shoot_web = true

func add_health(amount):
	health = min(health + amount, 100)


func _on_water_detection_water_state_changed(get_in_water: bool) -> void:
	self.in_water =  get_in_water
	if self.in_water:
		velocity.y = velocity.y * 0.6
