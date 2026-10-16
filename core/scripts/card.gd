extends Control

@onready var card_bgm = $CardBGM
@onready var card_background = $CardBackground # Certifique-se de que o TextureRect se chama CardBackground na cena
@onready var card_fade_fx = $CardFadeFX
@onready var card_fade_anim = $CardFadeAnim


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_card_theme()

	if card_fade_anim:
		card_fade_anim.play("fade_in")
	if card_bgm and not GameManager.is_bgm_muted:
		card_bgm.play()
	
	if card_bgm and not GameManager.is_bgm_muted:
		await card_bgm.finished
		card_fade_anim.play("fade_out")
	elif card_bgm and GameManager.is_bgm_muted:
		await get_tree().create_timer(8).timeout
		card_fade_anim.play("fade_out")
	
	await card_fade_anim.animation_finished
	get_tree().change_scene_to_file("res://core/scenes/levels/Map.tscn")

# Aplica as texturas e músicas específicas do ThemeData para o Card de Apresentação
func _apply_card_theme() -> void:
	var theme: ThemeData = GameManager.get_current_theme()
	if theme:
		if is_instance_valid(card_background) and theme.card_background:
			card_background.texture = theme.card_background
		if is_instance_valid(card_bgm) and theme.card_bgm:
			card_bgm.stream = theme.card_bgm
