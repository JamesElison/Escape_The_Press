extends Control

@onready var card_bgm = $CardBGM
@onready var card_fade_fx = $CardFadeFX
@onready var card_fade_anim = $CardFadeAnim


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if card_fade_anim:
		card_fade_anim.play("fade_in")
	if card_bgm:
		card_bgm.play()
	
	await card_bgm.finished
	card_fade_anim.play("fade_out")
	
	await card_fade_anim.animation_finished
	get_tree().change_scene_to_file("res://core/scenes/levels/Map.tscn")
	
