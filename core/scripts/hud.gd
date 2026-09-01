extends CanvasLayer

#signal start_game

var press_node
var level_music
var is_game_over: bool = false

#@onready var score_label = $ScoreLabel
@onready var HUD_color_rect = $HUDColorRect
@onready var message_label = $MessageLabel
@onready var start_button = $StartButton
@onready var message_timer = $MessageTimer

func _ready() -> void:
	press_node = get_parent().get_node("Press")
	level_music = get_parent().get_node("LevelMusic")


func show_message(text):
	message_label.text = text
	message_label.show()
	message_timer.start()

func show_game_over():
	is_game_over = true
	show_message("Game Over")
	await message_timer.timeout
	
	HUD_color_rect.show()
	message_label.text = "Escape The Press!"
	message_label.show()
	await get_tree().create_timer(1.0).timeout
	start_button.show()

#func update_score(score):
	#score_label.text = str(score)


func _on_start_button_pressed() -> void:
	# Se o jogador já morreu anteriormente, recarrega a cena inteira do zero
	if is_game_over:
		get_tree().reload_current_scene()
		return
	
	HUD_color_rect.hide()
	message_label.hide()
	start_button.hide()
	#start_game.emit()
	if "press_active" in press_node:
		press_node.press_active = true
	level_music.play()


func _on_mensage_timer_timeout() -> void:
	message_label.hide()
