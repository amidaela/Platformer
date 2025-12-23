extends Node

var current_scene: Node = null

var player_stats = {
	"health": 100,
}

func _ready():
	load_start_screen()

func load_start_screen():
	if current_scene:
		current_scene.queue_free()
	current_scene = preload("res://scenes/start_screen.tscn").instantiate()
	add_child(current_scene)
	current_scene.start_game.connect(_on_start_game)

func load_world():
	if current_scene:
		current_scene.queue_free()
	current_scene = preload("res://scenes/world.tscn").instantiate()
	current_scene.player_stats = player_stats
	add_child(current_scene)
	current_scene.room_cleared.connect(_on_room_cleared)
	current_scene.stats_updated.connect(_on_stats_updated)

func _on_start_game():
	load_tutorial()

func _on_room_cleared():
	load_world()

func _on_stats_updated(new_stats: Dictionary):
	player_stats = new_stats
	
func _on_tut_done():
	load_world()

func load_tutorial():
	if current_scene:
		current_scene.queue_free()
	current_scene = preload("res://scenes/tutorial.tscn").instantiate()
	add_child(current_scene)
	current_scene.tut_done.connect(_on_tut_done)
