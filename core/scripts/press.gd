extends CharacterBody2D

var press_active = false: set = set_press_active

@onready var press_hit_sound = $PressHitSound

# Lê a velocidade direto do GameManager
var speed: float = 3.0

func set_press_active(val: bool) -> void:
	press_active = val

func _ready() -> void:
	# Aplica a velocidade salva no GameManager
	speed = GameManager.press_speed

	# Ignora colisões com todos os blocos filhos já existentes
	for child in find_children("*", "AnimatableBody2D", true, false):
		add_collision_exception_with(child)

func _physics_process(delta: float) -> void:
	if not press_active:
		return

	var movement = Vector2.DOWN * speed * delta
	var collision = move_and_collide(movement)

	if collision:
		var collider = collision.get_collider()

		if collider.is_in_group("blocks") or "block_color" in collider:
			add_collision_exception_with(collider)
			return

		if (collider.name == "Player" or collider.is_in_group("player")) and collider.has_method("die"):
			collider.die()

func press_hit() -> void:
	if press_hit_sound:
		press_hit_sound.play()
