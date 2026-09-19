extends StaticBody2D

var player_node

@onready var health_shape = $FloorHealthArea/FloorHealthAreaShape
@onready var floor_sprite = $FloorSprite

# Referências para as piras de fogo
@onready var ancient_fire = $AncientFire
@onready var ancient_fire_2 = $AncientFire2

func _ready() -> void:
	find_player()
	update_floor_texture()

func update_floor_texture() -> void:
	var current_theme = GameManager.get_current_theme()
	
	if current_theme:
		# 1. Atualiza a textura do chão
		if current_theme.floor_texture and floor_sprite:
			floor_sprite.texture = current_theme.floor_texture
		
		# 2. Verifica se o tema atual é o Ancient Ruins pelo theme_id
		var is_ancient = (current_theme.theme_id == "120mm")
		
		# 3. Exibe/Esconde o fogo e ativa/desativa a emissão das partículas
		if is_instance_valid(ancient_fire):
			ancient_fire.visible = is_ancient
			ancient_fire.emitting = is_ancient

		if is_instance_valid(ancient_fire_2):
			ancient_fire_2.visible = is_ancient
			ancient_fire_2.emitting = is_ancient

func find_player() -> void:
	player_node = get_parent().get_node_or_null("Player")

func _on_floor_health_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("blocks"):
		if is_instance_valid(player_node) and player_node.has_method("die"):
			player_node.die()
