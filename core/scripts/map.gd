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

# Define qual fase o jogador deve jogar agora (Exemplo: 23)
var current_level: int = 1

func _ready() -> void:
	setup_and_position_stops()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Posiciona o jogador de início na parada alvo (ex: StopSprite_1)
	place_player_at_stop(current_level)
	update_camera_to_player()
	
	if map_bgm:
		map_bgm.play()

# Posiciona as paradas e aplica as regras visuais para cada uma
func setup_and_position_stops() -> void:
	for i in range(1, TOTAL_STOPS + 1):
		var node_name = "StopSprite_" + str(i)
		var sprite = stop_container.get_node_or_null(node_name)
	
		if sprite:
			stop_sprites.append(sprite)
			var new_y = START_Y - ((i - 1) * SPACING_Y)
			sprite.position.y = new_y
			
			# Configura o estado visual (Vortex/EnergyStop) se o script stop_sprite.gd estiver no nó
			if sprite.has_method("setup_state"):
				sprite.setup_state(current_level)

# Posiciona o jogador instantaneamente em cima de uma parada
func place_player_at_stop(stop_number: int) -> void:
	var target_sprite = get_stop_by_number(stop_number)
	if target_sprite:
		# Como o target_sprite está dentro do StopContainer e o StopContainer está em (0,0) do MapBackground,
		# podemos usar a posição local X e Y diretamente:
		map_player.position = target_sprite.position

# Move o jogador suavemente até uma parada específica e faz o ScrollContainer acompanhar
func move_player_to_stop(stop_number: int, duration: float = 1.8) -> void:
	var target_sprite = get_stop_by_number(stop_number)
	if not target_sprite:
		return
		
	var target_pos = target_sprite.position
	var half_screen = scroll_container.size.y / 2.0
	var target_scroll = int(target_pos.y - half_screen)
	
	# Cria uma animação suave em paralelo para o Player e para a Rolagem
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Movimenta o MapPlayer até a parada
	tween.tween_property(map_player, "position", target_pos, duration)
	
	# Rola a tela junto com o movimento do jogador
	tween.tween_property(scroll_container, "scroll_vertical", target_scroll, duration)


# Busca um nó de parada pelo número
func get_stop_by_number(number: int) -> Node2D:
	var node_name = "StopSprite_" + str(number)
	return stop_container.get_node_or_null(node_name) as Node2D

func update_camera_to_player() -> void:
	var target_y = map_player.position.y - (scroll_container.size.y / 2.0)
	scroll_container.scroll_vertical = int(target_y)

func _on_play_game_button_pressed() -> void:
	# Exemplo: Ao clicar no botão Jogar, você pode mover para a parada 1 ou a atual:
	move_player_to_stop(current_level)
