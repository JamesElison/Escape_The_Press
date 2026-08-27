extends CharacterBody2D

var press_active = true

@export var speed: float = 1.0 # Pixels por segundo
@export var push_force: float = 100.0

# Distância que a prensa recua ao ser atingida
@export var recoil_distance: float = 10.0 

func _physics_process(delta: float) -> void:
	if press_active:
		velocity = Vector2(0, speed)
		
		var collision = move_and_collide(velocity * delta, false, 0.08, true)
		
		if collision:
			var collider = collision.get_collider()
			
			# Regra 6: Se tocar no Player, o Player morre
			if collider.name == "Player" and collider.has_method("die"):
				collider.die()
				
			if collider is RigidBody2D:
				collider.linear_velocity.y = max(collider.linear_velocity.y, speed)
				# Regra 6: Se o bloco esmagar o Player por baixo
				for i in collider.get_colliding_bodies():
					if i.name == "Player" and i.has_method("die"):
						i.die()

		position.y += speed * delta

# Função chamada pela bola para recuar o dobro do avanço
#func hit_by_ball() -> void:
	## Aplica o recuo imediato subindo no eixo Y
	#position.y -= recoil_distance
