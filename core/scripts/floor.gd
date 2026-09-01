extends StaticBody2D

var player_node

@onready var health_shape = $FloorHealthArea/FloorHealthAreaShape

func _ready() -> void:
	find_player()

func find_player() -> void:
		player_node = get_parent().get_node("Player")
		#print(player_node)

func _on_floor_health_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("blocks"):
		if player_node.has_method("die"):
			player_node.die()
