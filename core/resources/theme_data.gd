# res://core/resources/theme_data.gd
class_name ThemeData
extends Resource

@export_category("Identificação do Cenário")
@export var theme_id: String = "crystal_palace"
@export var theme_name: String = "Crystal Palace"

@export_category("Background, Prensa e Lançador")
@export var background_texture: Texture2D
@export var press_texture: Texture2D
@export var launcher_texture: Texture2D
@export var floor_texture: Texture2D

@export_category("Músicas e Sons")
@export var bgm_music: AudioStream
@export var hit_sound: AudioStream
@export var explode_sound: AudioStream

@export_category("Caminhos de Sprites de Projéteis")
# Diretório base dos projéteis disparados (ex: "res://core/assets/sprites/set_objects/specific_projectiles/1_120mm_type/")
@export var projectile_folder: String = "res://core/assets/sprites/set_objects/"

@export_category("Caminhos de Sprites de Display do Charger")
# Diretório base dos displays no carregador
@export var display_folder: String = "res://core/assets/sprites/set_objects/"

@export_category("Caminhos de Sprites dos Blocos")
# Diretório base dos blocos no tabuleiro (ex: "res://core/assets/sprites/set_objects/specific_blocks/1_concrete/")
@export var block_folder: String = "res://core/assets/sprites/set_objects/"
