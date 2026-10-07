extends Control


@onready var map_bgm = $MapBGM
@onready var map_background = $ScrollContainer/MapBackground
# Variveis do portal:
@onready var portal_sprite = $ScrollContainer/MapBackground/PortalSprite
@onready var portal_vortex = $ScrollContainer/MapBackground/PortalSprite/PortalVortex
@onready var portal_energy_stop = $ScrollContainer/MapBackground/PortalSprite/PortalEnergyStop
@onready var portal_area = $ScrollContainer/MapBackground/PortalSprite/PortalArea
@onready var portal_area_shape = $ScrollContainer/MapBackground/PortalSprite/PortalArea/Shape
@onready var map_player = $ScrollContainer/MapBackground/MapPlayer

@onready var hud_fade_fx = $MapHUD/HUDFadeFX
@onready var hud_fade_anim = $MapHUD/HUDFadeAnim


func _ready() -> void:
	if map_bgm:
		map_bgm.play()


func _on_body_shop_button_pressed() -> void:
	pass # Replace with function body.


func _on_play_game_button_pressed() -> void:
	pass # Replace with function body.
