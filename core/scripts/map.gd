extends Control

@onready var map_bgm = $MapBGM
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

var stop_sprites: Array[Node] = []

const START_Y: float = 8760.0
const SPACING_Y: float = 180.0
const TOTAL_STOPS: int = 45

# Nível atual controlado pelo GameManager
var current_level: int = 1

func _ready() -> void:
	if GameManager:
		current_level = GameManager.current_level
		
	setup_and_position_stops()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Coloca o player na parada anterior para animar até a parada atual
	var previous_level = max(1, current_level - 1) if current_level > 1 else 1
	place_player_at_stop(previous_level)
	
	# Ajusta a tela no player na posição inicial
	update_camera_to_player()
	
	if map_bgm:
		map_bgm.play()
		
	# Se acabou de desbloquear uma nova parada, faz a animação de deslocamento suave!
	if current_level > 1 and previous_level != current_level:
		await get_tree().create_timer(0.4).timeout
		move_player_to_stop(current_level, 2.0)

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
	
	# Calcula a rotação direta para olhar em direção ao próximo nó (padrão 0 radianos = Direita)
	var direction = (target_pos - map_player.position)
	var target_rotation = direction.angle()
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Gira o player suavemente para a direção do movimento (em 0.4 segundos)
	tween.tween_property(map_player, "rotation", target_rotation, 0.4)
	
	# Move o MapPlayer até a nova parada
	tween.tween_property(map_player, "position", target_pos, duration)
	
	# Rola o ScrollContainer acompanhando o jogador
	tween.tween_property(scroll_container, "scroll_vertical", target_scroll, duration)

func get_stop_by_number(number: int) -> Node2D:
	var node_name = "StopSprite_" + str(number)
	return stop_container.get_node_or_null(node_name) as Node2D

func update_camera_to_player() -> void:
	var target_y = map_player.position.y - (scroll_container.size.y / 2.0)
	scroll_container.scroll_vertical = int(target_y)

# Ao clicar no botão "Jogar"
func _on_play_game_button_pressed() -> void:
	if GameManager:
		# Define formalmente o nível e a velocidade da prensa
		GameManager.set_level_from_stop(current_level)
		
	# Abre a cena de gameplay
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")
