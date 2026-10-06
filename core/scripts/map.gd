extends Control


@onready var map_bgm = $MapBGM
@onready var map_background = $ScrollContainer/MapBackground
# Variveis do portal:
@onready var portal_sprite = $ScrollContainer/MapBackground/PortalSprite
@onready var portal_vortex = $ScrollContainer/MapBackground/PortalSprite/PortalVortex
@onready var portal_energy_stop = $ScrollContainer/MapBackground/PortalSprite/PortalEnergyStop
@onready var portal_area = $ScrollContainer/MapBackground/PortalSprite/PortalArea
@onready var portal_area_shape = $ScrollContainer/MapBackground/PortalSprite/PortalArea/Shape
@onready var player = $ScrollContainer/MapBackground/Player
