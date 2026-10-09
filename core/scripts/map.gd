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

# O nível ativo é lido do GameManager
var current_level: int = 1

func _ready() -> void:
	# Lê o nível salvo no GameManager
	if GameManager:
		current_level = GameManager.current_level
		
	setup_and_position_stops()
	
	# Aguarda a renderização dos frames para garantir o tamanho dos containers de UI
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Inicia a câmera centralizada na posição original inicial do jogador
	update_camera_to_player()
	
	if map_bgm:
		map_bgm.play()
		
	# Pequeno intervalo antes de flutuar suavemente até a parada alvo
	await get_tree().create_timer(0.3).timeout
	move_player_to_stop(current_level, 2.5)

# Posiciona as paradas e aplica as regras visuais
func setup_and_position_stops() -> void:
	for i in range(1, TOTAL_STOPS + 1):
		var node_name = "StopSprite_" + str(i)
		var sprite = stop_container.get_node_or_null(node_name)
	
		if sprite:
			stop_sprites.append(sprite)
			var new_y = START_Y - ((i - 1) * SPACING_Y)
			sprite.position.y = new_y
			
			# Ajusta visibilidade do vortex/energy_stop
			if sprite.has_method("setup_state"):
				sprite.setup_state(current_level)

# Posiciona o jogador instantaneamente
func place_player_at_stop(stop_number: int) -> void:
	var target_sprite = get_stop_by_number(stop_number)
	if target_sprite:
		map_player.position = target_sprite.position

# Move o jogador com efeito de flutuação e faz o ScrollContainer acompanhar
func move_player_to_stop(stop_number: int, duration: float = 2.0) -> void:
	var target_sprite = get_stop_by_number(stop_number)
	if not target_sprite:
		return
		
	var target_pos = target_sprite.position
	var half_screen = scroll_container.size.y / 2.0
	var target_scroll = int(target_pos.y - half_screen)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Move o MapPlayer até a parada
	tween.tween_property(map_player, "position", target_pos, duration)
	
	# Acompanha a rolagem vertical da tela
	tween.tween_property(scroll_container, "scroll_vertical", target_scroll, duration)

# Busca uma parada pelo número correspondente
func get_stop_by_number(number: int) -> Node2D:
	var node_name = "StopSprite_" + str(number)
	return stop_container.get_node_or_null(node_name) as Node2D

func update_camera_to_player() -> void:
	var target_y = map_player.position.y - (scroll_container.size.y / 2.0)
	scroll_container.scroll_vertical = int(target_y)

# Transição para a cena de gameplay ao clicar no botão
func _on_play_game_button_pressed() -> void:
	# Define o nível e recala a velocidade da prensa no GameManager
	if GameManager:
		GameManager.set_level_from_stop(current_level)
		
	# Troca para a cena de gameplay
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")
