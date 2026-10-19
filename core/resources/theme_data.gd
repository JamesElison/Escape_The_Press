# res://core/resources/theme_data.gd
class_name ThemeData
extends Resource

@export_category("Identificação do Cenário")
@export var theme_id: String = "crystal_palace"
@export var theme_name: String = "Crystal Palace"


@export_category("Background, Floor e Prensa")
@export var card_background: Texture2D
@export var map_background: Texture2D
@export var background_texture: Texture2D
@export var floor_texture: Texture2D
#@export var press_texture: Texture2D


@export_category("Músicas e Sons")
@export var card_bgm: AudioStream
@export var map_bgm: AudioStream
@export var bgm_music: AudioStream
