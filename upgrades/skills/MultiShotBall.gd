extends SkillBase
class_name MultiShotBall
## Multi-Shot Ball — añade un balón extra por nivel al chutar.


func _init() -> void:
	id          = "multi_shot_ball"
	nombre      = "Multi-Shot Ball"
	descripcion = "Chutas +1 balón adicional (abanico)."
	nivel_max   = 4


func aplicar(_player: PlayerAgent, shooting: ShootingSystem) -> void:
	# nivel 1 → 2 balones, nivel 2 → 3, etc.
	shooting.set_multishot(1 + nivel_actual)
