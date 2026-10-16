# res://core/resources/launcher_themes/launcher_theme_data.gd
class_name LauncherThemeData
extends Resource

@export_category("Identificação do Lançador")
@export var launcher_id: String = "marble"
@export var launcher_name: String = "Marble"

@export_category("Launcher")
@export var launcher_texture: Texture2D
@export var launcher_map_texture: Texture2D

@export_category("Sons")
@export var hit_sound: AudioStream
@export var explode_sound: AudioStream

@export_category("Caminhos de Sprites de Projéteis")
# Diretório base dos projéteis disparados
@export var projectile_folder: String = "res://core/assets/sprites/set_objects/"

@export_category("Caminhos de Sprites de Display do Charger")
# Diretório base dos displays no carregador
@export var display_folder: String = "res://core/assets/sprites/set_objects/"

@export_category("Caminhos de Sprites dos Blocos")
# Diretório base dos blocos no tabuleiro
@export var block_folder: String = "res://core/assets/sprites/set_objects/"
