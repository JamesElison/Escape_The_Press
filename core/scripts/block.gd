extends AnimatableBody2D

const BLOCK_SCENE = preload("res://core/entities/enemies/block.tscn")
const GRID_SIZE: float = 64.0
const PARTICLES_SCENE = preload("res://core/entities/effects/block_explosion_particles.tscn")

var affected_block: bool = false: set = set_affected_block
var droped_block: bool = false: set = set_droped_block

var block_color: int = -1: set = set_block_color

var has_landed: bool = false
var is_being_destroyed: bool = false
var is_mystery_active: bool = false

@export var fall_speed: float = 600.0
var spawn_position: Vector2

@onready var block_color_change_sound = $BlockColorChangeSound
@onready var block_explode_sound = $BlockExplodeSound
@onready var block_explode_group_sound = $BlockExplodeGroupSound
@onready var block_move_down_sound = $BlockMoveDownSound
@onready var block_sprite = $BlockSprite
@onready var block_timer = $BlockTimer
@onready var shine_timer = $ShineTimer
@onready var block_anim = $BlockAnim
@onready var mystery_label = $MysteryLabel

const COLOR_FILENAMES = [
	"red_block.png", "green_block.png", "blue_block.png", 
	"cyan_block.png", "magenta_block.png", "yellow_block.png",
	"black_block.png", "white_block.png"
]
const BRIGHT_FILENAMES = [
	"red_block_bright.png", "green_block_bright.png", "blue_block_bright.png", 
	"cyan_block_bright.png", "magenta_block_bright.png", "yellow_block_bright.png",
	"black_block.png", "white_block.png"
]

func get_block_texture_path(idx: int, bright: bool = false) -> String:
	var theme = GameManager.get_current_theme()
	var folder = theme.block_folder
	var clamped_idx = clamp(idx, 0, COLOR_FILENAMES.size() - 1)
	var filename = BRIGHT_FILENAMES[clamped_idx] if bright else COLOR_FILENAMES[clamped_idx]
	
	var full_path = folder + filename
	if ResourceLoader.exists(full_path):
		return full_path
	return "res://core/assets/sprites/set_objects/" + filename

func set_block_color(val: int) -> void:
	block_color = val
	if is_node_ready() and block_sprite and val >= 0:
		var tex_path = get_block_texture_path(val)
		if ResourceLoader.exists(tex_path):
			block_sprite.texture = load(tex_path)

func _ready() -> void:
	update_theme_sounds()
	if is_instance_valid(mystery_label):
		mystery_label.hide()
		
	if block_color == -1:
		block_color = randi() % 6
	else:
		set_block_color(block_color)
	
	add_to_group("blocks")
	sync_to_physics = false

func set_mystery(active: bool) -> void:
	is_mystery_active = active
	if is_instance_valid(mystery_label):
		if active:
			mystery_label.show()
			if is_instance_valid(block_anim) and block_anim.has_animation("mystery"):
				block_anim.play("mystery")
		else:
			mystery_label.hide()
			if is_instance_valid(block_anim) and block_anim.is_playing():
				block_anim.stop()

func update_theme_sounds() -> void:
	var theme = GameManager.get_current_theme()
	if theme:
		if theme.explode_sound:
			if block_explode_sound:
				block_explode_sound.stream = theme.explode_sound
			if block_explode_group_sound:
				block_explode_group_sound.stream = theme.explode_sound

func _physics_process(delta: float) -> void:
	if droped_block and not has_landed:
		var movement = Vector2.DOWN * fall_speed * delta
		var collision = move_and_collide(movement)
		
		if collision:
			var collider = collision.get_collider()
			if collider.name == "Floor" or (collider is AnimatableBody2D and collider.has_landed):
				has_landed = true
				affected_block = true

func play_impact_animation() -> void:
	if block_anim and block_anim.has_animation("affected"):
		block_anim.play("affected")

func set_affected_block(val: bool) -> void:
	if affected_block == val:
		return
	affected_block = val
	if affected_block:
		play_impact_animation()
		EventBus.camera_shake_requested.emit(40.0, 0.2)
		affected_block = false

func set_droped_block(val: bool) -> void:
	if droped_block == val:
		return
		
	droped_block = val
	
	if droped_block:
		spawn_position = global_position
		play_impact_animation()
		
		await get_tree().create_timer(0.3).timeout
		
		if block_sprite:
			block_sprite.position = Vector2.ZERO
		
		var main_scene = get_tree().current_scene
		if get_parent() != main_scene:
			reparent(main_scene, true)
		
		await get_tree().create_timer(0.5).timeout
		spawn_replacement_block()
		
		if block_timer:
			block_timer.start(5.0)

func spawn_replacement_block() -> void:
	var press_node = get_tree().current_scene.find_child("Press", true, false)
	
	if press_node and BLOCK_SCENE:
		var new_block = BLOCK_SCENE.instantiate()
		var container = press_node.find_child("Block", true, false)
		if not container:
			container = press_node
			
		container.add_child(new_block)
		new_block.global_position = spawn_position
		
		if press_node.has_method("add_collision_exception_with"):
			press_node.add_collision_exception_with(new_block)

func play_color_change_sound() -> void:
	if block_color_change_sound:
		await get_tree().create_timer(0.10).timeout
		block_color_change_sound.play()

func destroy_with_delay() -> void:
	if is_being_destroyed:
		return
	is_being_destroyed = true
	
	GameManager.add_coins(10)
	spawn_particles()
	
	if block_sprite:
		block_sprite.hide()
	if is_instance_valid(mystery_label):
		mystery_label.hide()
	
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	if block_explode_sound:
		await get_tree().create_timer(0.10).timeout
		block_explode_sound.play()
		
	play_impact_animation()
	
	var destroyed_position = global_position
	contaminate_neighbors()
	
	if block_explode_sound and block_explode_sound.stream:
		await get_tree().create_timer(block_explode_sound.stream.get_length()).timeout
	else:
		await get_tree().create_timer(0.5).timeout
		
	trigger_column_rise(destroyed_position)
	queue_free()

func spawn_particles() -> void:
	if not PARTICLES_SCENE or block_color < 0:
		return
		
	var particle_instance = PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(particle_instance)
	particle_instance.global_position = global_position
	
	if particle_instance.has_method("setup"):
		particle_instance.setup(get_block_texture_path(block_color))

func contaminate_neighbors() -> void:
	var space_state = get_world_2d().direct_space_state
	var check_offsets = [
		Vector2.UP * GRID_SIZE,
		Vector2.DOWN * GRID_SIZE,
		Vector2.LEFT * GRID_SIZE,
		Vector2.RIGHT * GRID_SIZE
	]
	
	var group_sound_played: bool = false
	
	for offset in check_offsets:
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_position + offset
		query.collide_with_bodies = true
		
		var results = space_state.intersect_point(query)
		for result in results:
			var collider = result.collider
			if collider != self and "block_color" in collider:
				if collider.block_color == self.block_color and not collider.get("is_being_destroyed"):
					if block_explode_group_sound and not group_sound_played:
						block_explode_group_sound.play()
						group_sound_played = true
						
					get_tree().create_timer(0.1).timeout.connect(collider.destroy_with_delay)

func trigger_column_rise(from_position: Vector2) -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = from_position + Vector2.DOWN * GRID_SIZE
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	for result in results:
		var collider = result.collider
		if collider is AnimatableBody2D and "block_color" in collider and not collider.get("is_being_destroyed"):
			if collider.has_method("apply_upward_gravity"):
				collider.apply_upward_gravity()

func apply_upward_gravity() -> void:
	if is_being_destroyed or droped_block:
		return
		
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2.UP * GRID_SIZE
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	var space_above_free = true
	
	for result in results:
		var collider = result.collider
		if collider != self and not collider.get("is_being_destroyed"):
			space_above_free = false
			break
			
	if space_above_free:
		var tween = create_tween()
		tween.tween_property(self, "position:y", position.y - GRID_SIZE, 0.12)
		await tween.finished
		
		if block_move_down_sound:
			await get_tree().create_timer(0.10).timeout
			block_move_down_sound.play()
		
		trigger_column_rise(global_position + Vector2.DOWN * GRID_SIZE)
		apply_upward_gravity()
	else:
		check_top_match()
		check_line_matches()

func check_top_match() -> void:
	if is_being_destroyed:
		return
		
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2.UP * GRID_SIZE
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	for result in results:
		var collider = result.collider
		if collider != self and "block_color" in collider and not collider.get("is_being_destroyed"):
			if collider.block_color == self.block_color:
				destroy_with_delay()
				if collider.has_method("destroy_with_delay"):
					collider.destroy_with_delay()
				break

func check_line_matches() -> void:
	if is_being_destroyed or block_color < 0:
		return

	var space_state = get_world_2d().direct_space_state
	var blocks_to_destroy = []

	# 1. CHECAGEM HORIZONTAL
	var horizontal_group = [self]
	
	var current_pos = global_position + (Vector2.LEFT * GRID_SIZE)
	while true:
		var found = _get_matching_block_at(current_pos, space_state)
		if found and not found in horizontal_group:
			horizontal_group.append(found)
			current_pos += (Vector2.LEFT * GRID_SIZE)
		else:
			break
			
	current_pos = global_position + (Vector2.RIGHT * GRID_SIZE)
	while true:
		var found = _get_matching_block_at(current_pos, space_state)
		if found and not found in horizontal_group:
			horizontal_group.append(found)
			current_pos += (Vector2.RIGHT * GRID_SIZE)
		else:
			break

	if horizontal_group.size() >= 3:
		for b in horizontal_group:
			if not b in blocks_to_destroy:
				blocks_to_destroy.append(b)

	# 2. CHECAGEM VERTICAL
	var vertical_group = [self]
	
	current_pos = global_position + (Vector2.UP * GRID_SIZE)
	while true:
		var found = _get_matching_block_at(current_pos, space_state)
		if found and not found in vertical_group:
			vertical_group.append(found)
			current_pos += (Vector2.UP * GRID_SIZE)
		else:
			break
			
	current_pos = global_position + (Vector2.DOWN * GRID_SIZE)
	while true:
		var found = _get_matching_block_at(current_pos, space_state)
		if found and not found in vertical_group:
			vertical_group.append(found)
			current_pos += (Vector2.DOWN * GRID_SIZE)
		else:
			break

	if vertical_group.size() >= 3:
		for b in vertical_group:
			if not b in blocks_to_destroy:
				blocks_to_destroy.append(b)

	if blocks_to_destroy.size() >= 3:
		for b in blocks_to_destroy:
			if is_instance_valid(b) and b.has_method("destroy_with_delay"):
				b.destroy_with_delay()

func _get_matching_block_at(target_pos: Vector2, space_state: PhysicsDirectSpaceState2D) -> Node2D:
	var query = PhysicsPointQueryParameters2D.new()
	query.position = target_pos
	query.collide_with_bodies = true
	var results = space_state.intersect_point(query)
	
	for result in results:
		var collider = result.collider
		if collider != self and "block_color" in collider and not collider.get("is_being_destroyed"):
			if collider.block_color == self.block_color:
				return collider
	return null

func shift_down() -> void:
	if is_being_destroyed:
		return

	GameManager.coins -= 10
	EventBus.coins_updated.emit(GameManager.coins)
	GameManager.save_game_data()

	if block_move_down_sound:
		await get_tree().create_timer(0.10).timeout
		block_move_down_sound.play()
		
	play_impact_animation()

	var target_y = position.y + GRID_SIZE
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", target_y, 0.15)
	
	await tween.finished
	await get_tree().create_timer(0.05).timeout

	check_line_matches()
	notify_neighbors_to_check()

func notify_neighbors_to_check() -> void:
	if is_being_destroyed:
		return
	var space_state = get_world_2d().direct_space_state
	var offsets = [
		Vector2.LEFT * GRID_SIZE,
		Vector2.RIGHT * GRID_SIZE,
		Vector2.UP * GRID_SIZE,
		Vector2.DOWN * GRID_SIZE
	]
	for offset in offsets:
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_position + offset
		query.collide_with_bodies = true
		var results = space_state.intersect_point(query)
		for result in results:
			var collider = result.collider
			if collider != self and collider.has_method("check_line_matches") and not collider.get("is_being_destroyed"):
				collider.check_line_matches()

func _on_block_timer_timeout() -> void:
	queue_free()

func fade_to_color(new_color_index: int) -> void:
	if not block_sprite or new_color_index < 0:
		block_color = new_color_index
		return

	var temp_sprite = Sprite2D.new()
	temp_sprite.texture = block_sprite.texture
	temp_sprite.position = block_sprite.position
	temp_sprite.scale = block_sprite.scale
	temp_sprite.centered = block_sprite.centered
	
	add_child(temp_sprite)
	block_color = new_color_index

	var tween = create_tween()
	tween.tween_property(temp_sprite, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	temp_sprite.queue_free()
	
	check_line_matches()
