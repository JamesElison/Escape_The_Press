extends Control

@onready var body_shop_rect: ColorRect = $BodyShopRect

# Variáveis para controle do Scroll / Drag
var is_dragging: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO

# Limites exatos baseados na altura de 2640px e posição inicial -40.0
@export var max_y: float = -40.0
@export var min_y: float = -1400.0  # Altere para -1680.0 se sua tela tiver 1000px de altura

func _ready() -> void:
	InAppManager.item_purchased.connect(_on_item_purchased)
	update_shop_ui()

func _gui_input(event: InputEvent) -> void:
	# 1. Detecta o toque/clique na tela
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			last_touch_pos = event.position
		else:
			is_dragging = false
			
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			last_touch_pos = event.position
		else:
			is_dragging = false

	# 2. Arrasta o ColorRect verticalmente
	if is_dragging:
		if event is InputEventScreenDrag:
			var delta_y = event.position.y - last_touch_pos.y
			move_shop(delta_y)
			last_touch_pos = event.position
			
		elif event is InputEventMouseMotion:
			var delta_y = event.position.y - last_touch_pos.y
			move_shop(delta_y)
			last_touch_pos = event.position

func move_shop(delta_y: float) -> void:
	if not body_shop_rect:
		return
		
	var new_y = body_shop_rect.position.y + delta_y
	# Trava a rolagem entre a posição inicial (-40) e o fim do ColorRect
	body_shop_rect.position.y = clamp(new_y, min_y, max_y)

func _on_launcher_pressed(launcher_key: String) -> void:
	if launcher_key in InAppManager.purchased_launchers:
		equip_launcher(launcher_key)
	else:
		InAppManager.buy_launcher(launcher_key)

func _on_item_purchased(launcher_key: String) -> void:
	update_shop_ui()

func update_shop_ui() -> void:
	pass

func equip_launcher(launcher_key: String) -> void:
	pass
