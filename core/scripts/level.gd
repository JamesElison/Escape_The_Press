extends Node2D


@onready var press = $Press


func game_over() -> void:
	if "press_active" in press:
		press.press_active = false
