# caterpillar.gd
extends CharacterBody2D

@export var health = 50
@export var damage = 10
@export var move_speed = 60
@export var detection_range = 300
@export var attack_range = 50
@export var attack_cooldown = 2

var drowning = false
var drown_wait = false
var player = null
var can_attack = true
var is_disabled = false
var gravity = 980
var started = false

signal died

func _ready():
	add_to_group("enemies")
	
	player = get_tree().get_first_node_in_group("player")
	
func _process(_delta: float) -> void:
	if drowning:
		if !drown_wait:
			take_damage(10)
			drown_wait = true
			await get_tree().create_timer(1).timeout
			drown_wait = false
		

func _physics_process(delta):
	$ProgressBar.value = health
	if drowning:
		if $AnimatedSprite2D.animation == "idle_left":
			$AnimatedSprite2D.play("hurt_left")
		else:
			$AnimatedSprite2D.play("hurt_right")
		if !is_on_floor():
			velocity.y += gravity * delta * 0.6
		move_and_slide()
		return
	
	if !started:
		if Input.is_anything_pressed():
			started = true
		$AnimatedSprite2D.play("idle_left")
		if !is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return
		
	if is_disabled:
		velocity.x=0
		if $AnimatedSprite2D.animation == "idle_left":
			$AnimatedSprite2D.play("web_left")
		else:
			$AnimatedSprite2D.play("web_right")
		if !is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return
		
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return 
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if !is_on_floor():
		velocity.y += gravity * delta
		
	if player == null:
		$AnimatedSprite2D.play("idle_left")
		move_and_slide()
		return
	
	if distance_to_player <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * move_speed * GlobalStats.get_enemy_speed_multiplier()

		if velocity.x > 0:
			$AnimatedSprite2D.play("right")
		else:
			$AnimatedSprite2D.play("idle_left")
		
		if distance_to_player <= attack_range and can_attack:
			attack()
	else:
		velocity.x = 0
		$AnimatedSprite2D.play("idle_left")
	
	if position.y >= 320:
		die()
	
	#boundaries
	position.x = max(0, position.x)
	position.x = min(640, position.x)
	position.y = max(0, position.y)
	position.y = min(320, position.y)
	
	move_and_slide()

func attack():
	if can_attack and player != null:
		can_attack = false

		var dir = (player.global_position - global_position).normalized()
		var lunge_distance = 20
		var settle_back_distance = 30 
		var lunge_speed = 200

		var start_pos = global_position
		var lunge_pos = start_pos + dir * lunge_distance
		var settle_pos = start_pos + dir * settle_back_distance

		var tween = create_tween()

		tween.tween_property(self, "global_position", lunge_pos, lunge_distance / float(lunge_speed))
		tween.tween_callback(Callable(self, "_deal_damage"))
		tween.tween_property(self, "global_position", settle_pos, (lunge_distance - settle_back_distance) / float(lunge_speed))

		var adjusted_attack_cooldown = attack_cooldown * GlobalStats.get_enemy_cooldown_multiplier()
		await get_tree().create_timer(adjusted_attack_cooldown).timeout
		can_attack = true

func _deal_damage():
	if player and global_position.distance_to(player.global_position) <= attack_range:
		var scaled_damage = damage * GlobalStats.get_enemy_attack_multiplier()
		var dir = sign(-player.position.x + position.x)
		player.take_damage(scaled_damage, dir)

func take_damage(damage_amount):
	health -= damage_amount
	
	if health <= 0:
		die()

func die():
	died.emit()
	queue_free()

func disable(duration):
	if is_disabled:
		return
	is_disabled = true

	# restore after duration
	await get_tree().create_timer(duration).timeout
	is_disabled = false


func _on_water_detection_water_state_changed(in_water: bool) -> void:
	if in_water:
		drowning = true
	else:
		drowning = false
