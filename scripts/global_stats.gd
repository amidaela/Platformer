extends Node

var deaths = 0
var hits_taken = 0
var level_active = false
var timer_started = false
var difficulty = 0.0 
var level_timer: Timer
var label_shown = false
var health

func start_level():
	deaths = 0
	hits_taken = 0
	level_active = true
	timer_started = false
	
func _ready() -> void:
	level_timer = Timer.new()
	level_timer.one_shot = true
	level_timer.wait_time = 999999.0
	add_child(level_timer)

func _process(_delta):
	if timer_started:
		return
		
	if Input.is_anything_pressed():
		timer_started = true
		level_timer.start()
		
func get_level_time():
	return level_timer.wait_time - level_timer.time_left

func compute_performance_score() -> float:
	var score = 1.0
	var target_time = 15.0
	var level_time = get_level_time()
	var target_health = 70
	# penalties for long completion time, deaths and hits taken
	
	score -= min((level_time - target_time) /200.0, 0.5 )

	if deaths > 0:
		score -= min(0.1 * (deaths), 0.5)

	if hits_taken > 10:
		score -= min(hits_taken / 500.0, 0.5)
		
	score -= min((target_health-health) / 100.0, 0.5)
		
	print("time: ", level_time/1, ", deaths: ", deaths, ", hits: ", hits_taken, ", health: ", health)

	return clamp(score, 0.0, 1.0)
	

func update_difficulty():
	var score = compute_performance_score()
	var target_difficulty = lerp(0.5, 3.0, score)
	print("score: ", score, ", target: ", target_difficulty)
	difficulty = lerp(difficulty, target_difficulty, 0.2)  

func get_player_attack_multiplier() -> float:
	return lerp(1.2, 0.5, clamp(difficulty / 3.0, 0, 1)) 

func get_enemy_attack_multiplier() -> float:
	return lerp(0.5, 1.5, clamp(difficulty / 3.0, 0, 1))

func get_enemy_speed_multiplier() -> float:
	return lerp(0.7, 2.0, clamp(difficulty / 3.0, 0, 1))

func get_player_cooldown_multiplier() -> float:
	return lerp(0.5, 2.0, clamp(difficulty / 3.0, 0, 1))

func get_enemy_cooldown_multiplier() -> float:
	return lerp(1.5, 0.5, clamp(difficulty / 3.0, 0, 1))

func get_disable_multiplier() -> float:
	return lerp(1.5, 0.5, clamp(difficulty / 3.0, 0, 1))
