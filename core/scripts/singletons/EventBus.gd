# EventBus.gd (Configure em Project Settings -> Autoload com o nome EventBus)
extends Node

# Sinal global que qualquer objeto pode emitir
signal camera_shake_requested(intensity: float, duration: float)
signal coins_updated(new_amount: int)
signal launcher_changed(launcher_id: String)
