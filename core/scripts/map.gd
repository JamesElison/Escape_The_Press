extends Control

@onready var map_bgm = $MapBGM
@onready var end_map_bgm = $EndMapBGM
@onready var map_background = $ScrollContainer/MapBackground
@onready var scroll_container = $ScrollContainer

# Variáveis do portal:
@onready var portal_sprite = $ScrollContainer/MapBackground/PortalSprite
@onready var portal_vortex = $ScrollContainer/MapBackground/PortalSprite/PortalVortex
@onready var portal_energy_stop = $ScrollContainer/MapBackground/PortalSprite/PortalEnergyStop
@onready var portal_area = $ScrollContainer/MapBackground/PortalSprite/PortalArea
@onready var portal_area_shape = $ScrollContainer/MapBackground/PortalSprite/PortalArea/Shape

# Variáveis de entities:
@onready var stop_container = $ScrollContainer/MapBackground/StopContainer
@onready var map_player = $ScrollContainer/MapBackground/MapPlayer

# Variáveis de MapHUD:
@onready var hud_fade_fx = $MapHUD/HUDFadeFX
@onready var hud_fade_anim = $MapHUD/HUDFadeAnim

# Variáveis de SnowFX:
@onready var fog_overlay = $FogCanvas/FogOverlay
@onready var snow_fx = $SnowFX

var stop_sprites: Array[Node] = []

const START_Y: float = 8760.0
const SPACING_Y: float = 180.0
const TOTAL_STOPS: int = 45

# Nível atual controlado pelo GameManager
var current_level: int = 1

func _ready() -> void:
	if GameManager:
		current_level = GameManager.current_level
		
	# Aplica o tema visual e sonoro do bioma atual no Mapa
	_apply_map_theme()
	
	especific_fx()
	
	setup_and_position_stops()
	
	# Verifica e gerencia a visibilidade do portal_energy_stop na casa 45
	_check_portal_energy_stop_visibility()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Se acabou de vencer o nível 45, o player deve começar na parada 45 antes de ir para o portal
	if GameManager.just_beat_final_level:
		place_player_at_stop(45)
		update_camera_to_player()
		await get_tree().create_timer(0.4).timeout
		_trigger_portal_sequence()
		return
	
	# Comportamento padrão para níveis normais
	var previous_level = max(1, current_level - 1) if current_level > 1 else 1
	place_player_at_stop(previous_level)
	update_camera_to_player()
	
	if map_bgm and not GameManager.is_bgm_muted:
		map_bgm.play()
		
	if current_level > 1 and previous_level != current_level:
		await get_tree().create_timer(0.4).timeout
		move_player_to_stop(current_level, 2.0)

func _check_portal_energy_stop_visibility() -> void:
	if portal_energy_stop:
		if current_level >= 45 or GameManager.just_beat_final_level:
			portal_energy_stop.show()
		else:
			portal_energy_stop.hide()

func especific_fx() -> void:
	if GameManager.equipped_launcher == "sub_zero":
		fog_overlay.show()
		snow_fx.show()
	else:
		fog_overlay.hide()
		snow_fx.hide()

# Aplica as texturas e músicas específicas do ThemeData para o Mapa
func _apply_map_theme() -> void:
	var theme: ThemeData = GameManager.get_current_theme()
	if theme:
		if is_instance_valid(map_background) and theme.map_background:
			map_background.texture = theme.map_background
		if is_instance_valid(map_bgm) and theme.map_bgm:
			map_bgm.stream = theme.map_bgm

# Posiciona as paradas e aplica os estados visuais (Vortex / Energy Stop)
func setup_and_position_stops() -> void:
	for i in range(1, TOTAL_STOPS + 1):
		var node_name = "StopSprite_" + str(i)
		var sprite = stop_container.get_node_or_null(node_name)
	
		if sprite:
			stop_sprites.append(sprite)
			var new_y = START_Y - ((i - 1) * SPACING_Y)
			sprite.position.y = new_y
			
			if sprite.has_method("setup_state"):
				sprite.setup_state(current_level)

# Posiciona o jogador instantaneamente
func place_player_at_stop(stop_number: int) -> void:
	var target_sprite = get_stop_by_number(stop_number)
	if target_sprite:
		map_player.position = target_sprite.position

# Move o jogador com rotação, interpolação suave (flutuação) e rola a tela junto
func move_player_to_stop(stop_number: int, duration: float = 2.0) -> void:
	var target_sprite = get_stop_by_number(stop_number)
	if not target_sprite:
		return
		
	var target_pos = target_sprite.position
	var half_screen = scroll_container.size.y / 2.0
	var target_scroll = int(target_pos.y - half_screen)
	
	var direction = (target_pos - map_player.position)
	var target_rotation = direction.angle()
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(map_player, "rotation", target_rotation, 0.4)
	tween.tween_property(map_player, "position", target_pos, duration)
	tween.tween_property(scroll_container, "scroll_vertical", target_scroll, duration)

# Sequência especial ao vencer o nível 45: Vai até o portal e entra nele
func _trigger_portal_sequence() -> void:
	if not portal_sprite:
		return
		
	if map_bgm and not GameManager.is_bgm_muted and not map_bgm.playing:
		map_bgm.play()

	var target_pos = portal_sprite.position
	var half_screen = scroll_container.size.y / 2.0
	var target_scroll = int(target_pos.y - half_screen)
	
	# 1. Olha para o portal
	var direction = (target_pos - map_player.position)
	var target_rotation = direction.angle()
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(map_player, "rotation", target_rotation, 0.4)
	
	await tween.finished
	
	# 2. Direciona-se até o portal vagarosamente (2.0 segundos)
	var move_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	move_tween.tween_property(map_player, "position", target_pos, 2.0)
	move_tween.tween_property(scroll_container, "scroll_vertical", target_scroll, 2.0)
	
	await move_tween.finished
	
	# 3. Entrou no portal: toca áudio end_map e animação hud_fade_anim ("end_map")
	if map_bgm and map_bgm.playing:
		map_bgm.stop()
		
	if end_map_bgm and not GameManager.is_bgm_muted:
		end_map_bgm.play()
		await end_map_bgm.finished
		
	if hud_fade_anim:
		hud_fade_anim.play("fade_out")
		await hud_fade_anim.animation_finished
		
	# 4. Agora sim, aplica a virada de cenário real no GameManager e vai para o card
	GameManager.finalize_cycle_advancement()
	get_tree().change_scene_to_file("res://core/scenes/levels/card.tscn")

func get_stop_by_number(number: int) -> Node2D:
	var node_name = "StopSprite_" + str(number)
	return stop_container.get_node_or_null(node_name) as Node2D

func update_camera_to_player() -> void:
	var target_y = map_player.position.y - (scroll_container.size.y / 2.0)
	scroll_container.scroll_vertical = int(target_y)

# Ao clicar no botão "Jogar"
func _on_play_game_button_pressed() -> void:
	if GameManager:
		GameManager.set_level_from_stop(current_level)
		
	get_tree().change_scene_to_file("res://core/scenes/levels/game_play_area.tscn")
