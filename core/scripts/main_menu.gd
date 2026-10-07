extends Node2D

@onready var fade_anim =$MainMenuBackGround/FadeAnim

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if fade_anim:
		fade_anim.play("fade_in")
