extends CharacterBody2D

var press_active = true

@export var speed: float = 1.0 # Pixels por segundo

func _physics_process(delta: float) -> void:
	if press_active:
		velocity = Vector2(0, speed)
		
		# Move a prensa (e por consequência todos os blocos anexados como filhos)
		var collision = move_and_collide(velocity * delta, false, 0.08, true)
		
		if collision:
			var collider = collision.get_collider()
			# Regra 6: Se a Prensa tocar no Player, o Player morre
			if collider.name == "Player" and collider.has_method("die"):
				collider.die()

		position.y += speed * delta
