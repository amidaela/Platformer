extends Control

signal start_game

func _ready():
	$StartButton.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	start_game.emit()
