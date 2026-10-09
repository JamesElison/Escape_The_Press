extends Node


func stop_with_fade_out(player: AudioStreamPlayer, duration: float = 1.0) -> void:
	if not is_instance_valid(player) or not player.playing:
		return
	
	var original_volume: float = player.volume_db
	var tween := create_tween()
	
	tween.tween_property(player, "volume_db", -80.0, duration)\
	.set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func():
		if is_instance_valid(player):
			player.stop()
			player.volume_db = original_volume
		)
