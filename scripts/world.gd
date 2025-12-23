extends Node2D

@onready var player_scene = preload("res://scenes/player.tscn")
@onready var bee_scene = preload("res://scenes/bee.tscn")
@onready var caterpillar_scene = preload("res://scenes/caterpillar.tscn")
@onready var fly_scene = preload("res://scenes/fly.tscn")
@onready var gate_scene = preload("res://scenes/gate.tscn")

var rng = RandomNumberGenerator.new()
var spawn_points = []
var difficulty = 0
var current_seed = 0

signal room_cleared
signal stats_updated(new_stats: Dictionary)

@export var player_stats: Dictionary = {}
var enemy_spawn_data := []
var enemies_alive := 0


signal room_empty

func _ready():
	current_seed = Time.get_unix_time_from_system()
	_generate_new_room()


func _generate_new_room():
	rng.seed = current_seed
	spawn_points.clear()
	$Room.clear()
	generate_ground()
	generate_room()
	generate_enemies()
	add_player(Vector2(16, 32 * 5))

func generate_ground():
	for i in range(20):
		$Room.set_cell(Vector2(i, 7), 4, Vector2(0, 0))
		$Room.set_cell(Vector2(i, 8), 4, Vector2(0, 1))
		$Room.set_cell(Vector2(i, 9), 4, Vector2(0, 1))

func add_player(pos: Vector2):
	var player = player_scene.instantiate()
	player.position = pos
	add_child(player)
	player.health = player_stats.get("health", 100)
	
	player.reached_exit.connect(_on_player_reached_exit)
	player.died.connect(_on_player_died)

func _on_player_died():
	GlobalStats.deaths += 1
	await get_tree().create_timer(1.0).timeout
	player_stats["health"] = 100  # reset health on death
	respawn_player()

func respawn_player():
	for child in get_children():
		if child.is_in_group("player"):
			child.queue_free()
		elif child.is_in_group("enemies"):
			child.queue_free()
		elif child.is_in_group("gate"):
			child.queue_free()
	if GlobalStats.difficulty > 1.3:
		var gate = gate_scene.instantiate()
		gate.position = Vector2(640,0)
		add_child(gate)
	add_player(Vector2(16, 32 * 5))
	spawn_enemies_from_data()

func _on_player_reached_exit():
	player_stats["health"] = get_node("Player").health if has_node("Player") else player_stats["health"]
	stats_updated.emit(player_stats)
	GlobalStats.level_active = false
	GlobalStats.update_difficulty()
	# generate next room with a new seed
	GlobalStats.start_level() # resets stats for difficulty
	room_cleared.emit() # room gets generated

func add_bee(pos: Vector2):
	var bee = bee_scene.instantiate()
	bee.position = pos
	add_child(bee)
	return bee
	
func add_caterpillar(pos: Vector2):
	var caterpillar = caterpillar_scene.instantiate()
	caterpillar.position = pos
	add_child(caterpillar)
	return caterpillar
	
func add_fly(pos: Vector2):
	var fly = fly_scene.instantiate()
	fly.position = pos
	add_child(fly)

func generate_room():
	for i in range(4):
		generate_chunk()
	for i in range(4):
		if rand(0,1)==1:
			generate_chunk()
			
	fill_gaps()
			
	if GlobalStats.difficulty > 1.3:
		var gate = gate_scene.instantiate()
		gate.position = Vector2(640,0)
		add_child(gate)
		
func generate_chunk():
	var x = rand(0,3)
	
	if x==0:
		generate_gap()
	elif x==1:
		generate_platform()
	elif x==2:
		generate_hill()
	elif x==3:
		generate_water()
		
func rand(a:int,b:int):
	var x = rng.randi_range(a,b)
	return x
	
func generate_gap():
	var width = rand(1,2)
	var x = rand(1,19-width)
	for i in range(3):
		$Room.erase_cell(Vector2(x,9-i))
		if width == 2:
			$Room.erase_cell(Vector2(x+1,9-i))
			
	# column next to gap so there can't be water
	for i in range(2):
		$Room.set_cell(Vector2(x-1,9-i), 4, Vector2(0,1))
		$Room.set_cell(Vector2(x+width,9-i), 4, Vector2(0,1))
	$Room.set_cell(Vector2(x-1,7), 4, Vector2(0,0))
	$Room.set_cell(Vector2(x+width,7), 4, Vector2(0,0))

func generate_platform():
	var width = rand(1,3)
	var x = rand(1, 18-width)
	var y = rand(4,5)
	for i in range(width):
		$Room.set_cell(Vector2(x+i,y),4,Vector2(1,0))
	@warning_ignore("integer_division")
	spawn_points.append(Vector2(x+(width/2), y-1))

func generate_hill():
	var width = rand(3,5)
	var x = rand(1,19-width)
	$Room.set_cell(Vector2(x,6),4,Vector2(1,0))
	$Room.set_cell(Vector2(x,7),4,Vector2(0,1))
	for i in range(width-1):
		$Room.set_cell(Vector2(x+i+1,6),4,Vector2(0,0))
		$Room.set_cell(Vector2(x+i+1,7),4,Vector2(0,1))
	$Room.set_cell(Vector2(x+width-1,6),4,Vector2(1,0))
	$Room.set_cell(Vector2(x+width-1,7),4,Vector2(0,1))
	@warning_ignore("integer_division")
	spawn_points.append(Vector2(x+width/2, 5))

func generate_fly():
	var width = rand(1,3)
	var x = rand(1,19-width)*32+16
	var y = rand(4,6)*32+16
	for i in range(width):
		add_fly(Vector2(x+32*i,y))

func generate_enemies():
	for i in range(2, 18):
		if $Room.get_cell_tile_data(Vector2(i, 7)) == null:
			pass
		elif $Room.get_cell_atlas_coords(Vector2(i, 7)) == Vector2i(1,1):
			pass
		else:
			spawn_points.append(Vector2(i, 6))
	
	# remove points that arent empty
	spawn_points = spawn_points.filter(func(p):
		return $Room.get_cell_tile_data(p) == null
	)
	spawn_points = spawn_points.duplicate(true) # remove duplicates
	
	shuffle_with_rand(spawn_points)

	var base_enemy_count = 1
	var base_fly_count = 5
	# scale number of enemies and flies with difficulty
	var enemy_count = clamp(base_enemy_count + int(GlobalStats.difficulty * 1.5), 1, spawn_points.size())
	var fly_count = clamp(base_fly_count - int(GlobalStats.difficulty), 0, spawn_points.size())

	var index = 0
	
	# enemies
	for i in range(enemy_count):
		if index >= spawn_points.size():
			break

		var pos = spawn_points[index] * 32 + Vector2(16, 16)
		index += 1

		var enemy_type = rand(0, 1)
		var type_name = "bee" if enemy_type == 0 else "caterpillar"
		enemy_spawn_data.append({
			"type": type_name,
			"pos": pos
		})

	# flies
	for i in range(fly_count):
		if index >= spawn_points.size():
			break
		enemy_spawn_data.append({
			"type": "fly",
			"pos": spawn_points[index] * 32 + Vector2(16, 16)
		})
		index += 1
	
	print("difficulty: ", GlobalStats.difficulty, ", enemies: ", enemy_count, ", flies: ", fly_count)
	
	spawn_enemies_from_data()

func generate_water():
	var width = rand(1,2)
	var x = rand(1,19-width)
	for i in range(width):
		$Room.set_cell(Vector2(x+i,9),4,Vector2(0,1))
		$Room.set_cell(Vector2(x+i,8),4,Vector2(2,1))
		$Room.set_cell(Vector2(x+i,7),4,Vector2(1,1))
	# dirt columns around water to prevent water next to a gap
	$Room.set_cell(Vector2(x-1,9),4,Vector2(0,1))
	$Room.set_cell(Vector2(x-1,8),4,Vector2(0,1))
	$Room.set_cell(Vector2(x-1,7),4,Vector2(0,0))
	$Room.set_cell(Vector2(x+width,9),4,Vector2(0,1))
	$Room.set_cell(Vector2(x+width,8),4,Vector2(0,1))
	$Room.set_cell(Vector2(x+width,7),4,Vector2(0,0))

func spawn_enemies_from_data():
	enemies_alive = 0
	for data in enemy_spawn_data:
		var enemy
		match data.type:
			"bee":
				enemy = add_bee(data.pos)
			"caterpillar":
				enemy = add_caterpillar(data.pos)
			"fly":
				add_fly(data.pos)
		if enemy:
			enemies_alive += 1
			enemy.died.connect(_on_enemy_died)

func _on_enemy_died():
	enemies_alive -= 1
	if enemies_alive == 0:
		room_empty.emit()

func shuffle_with_rand(arr):
	for i in range(arr.size() - 1, 0, -1):
		var j = rand(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func fill_column(x,h=0):
	for i in range(0,3+h):
		$Room.erase_cell(Vector2(x, 9-i))
		$Room.set_cell(Vector2(x, 9-i), 4, Vector2(0,1))
		
func fill_gaps():
	for i in range(1,20):
		if $Room.get_cell_tile_data(Vector2(i,6)):
			fill_column(i)
			if $Room.get_cell_tile_data(Vector2(i,5)):
				$Room.erase_cell(Vector2(i,5))
		if $Room.get_cell_tile_data(Vector2(i,5)) and $Room.get_cell_tile_data(Vector2(i,4)):
			$Room.erase_cell(Vector2(i,4))
