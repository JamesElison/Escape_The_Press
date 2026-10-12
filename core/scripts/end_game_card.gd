extends Control

const WINNER_PARTICLES_SCENE = preload("res://core/entities/effects/winner_particles.tscn")

@onready var end_game_bgm = $HUD/EngGameBGM
@onready var card_fade_anim =$HUD/CardFadeAnim
@onready var winner_message_marker = $HUD/WinnerMessageMarker

func _ready() -> void:
	end_game_play()


func end_game_play() -> void:
	card_fade_anim.play("fade_in")
	spawn_winner_particles()
	end_game_bgm.play()
	await end_game_bgm.finished
	card_fade_anim.play("fade_out")
	
	get_tree().change_scene_to_file("res://core/scenes/set_elements/main_menu.tscn")


func spawn_winner_particles() -> void:
	if not WINNER_PARTICLES_SCENE:
		return
		
	var particle_instance = WINNER_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(particle_instance)
	
	if is_instance_valid(winner_message_marker):
		particle_instance.global_position = winner_message_marker.global_position
	
	particle_instance.z_index = 100
	
	if particle_instance.has_method("setup"):
		particle_instance.setup()


func _on_back_button_pressed() -> void:
	if end_game_bgm and end_game_bgm.playing:
		AudioManager.stop_with_fade_out(end_game_bgm, 1.0)
	await end_game_bgm.finished
	get_tree().change_scene_to_file("res://core/scenes/set_elements/main_menu.tscn")
