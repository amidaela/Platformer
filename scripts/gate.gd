extends StaticBody2D

@export var open_distance := 64.0
@export var open_time := 0.6

func _ready():
	if GlobalStats.label_shown:
		$Label.visible = false
	else:
		$Label.visible = true
	await get_tree().process_frame
	var room = get_tree().get_first_node_in_group("room")
	if room:
		room.room_empty.connect(_on_room_cleared)
	await get_tree().create_timer(3).timeout
	GlobalStats.label_shown = true
	$Label.visible = false

func _on_room_cleared():
	open_gate()
	print("Opening gate!")

func open_gate():
	var tween := create_tween()
	tween.tween_property(
		self,
		"position:y",
		position.y - open_distance,
		open_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
