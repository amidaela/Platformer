extends Node2D
signal tut_done
signal AD_pressed
signal jumped
signal attack
signal web


func _ready() -> void:
	$Button.pressed.connect(_on_button_pressed)
	$Label.text = "welcome!"
	await get_tree().create_timer(2).timeout
	$Label.text = "press a to move left and d to move right"
	await AD_pressed
	$Label.text = ""
	await get_tree().create_timer(0.5).timeout
	$Label.text = "press w or space to jump"
	await jumped
	$Label.text = ""
	await get_tree().create_timer(0.5).timeout
	$Label.text = "press q/e or right click to attack"
	await attack
	$Label.text = ""
	await get_tree().create_timer(0.5).timeout
	$Label.text = "left click to shoot a web"
	await web
	$Label.text = ""
	await get_tree().create_timer(0.5).timeout
	$Label.text = "to continue to the next level, you must reach the right side of the screen."
	await get_tree().create_timer(3).timeout
	$Label.text = ""
	await get_tree().create_timer(0.5).timeout
	$Label.text = "have fun!"

	
	

func _process(_delta: float) -> void:
	if $Player.position.x > 640:
		tut_done.emit()
	
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		AD_pressed.emit()
		
	if Input.is_action_just_pressed("jump"):
		jumped.emit()
		
	if Input.is_action_just_pressed("attack")or Input.is_action_just_pressed("attack_left")or Input.is_action_just_pressed("attack_right"):
		attack.emit()
		
	if Input.is_action_just_pressed("shoot"):
		web.emit()
		
func _on_button_pressed():
	tut_done.emit()
