extends SkillBase
class_name SpeedBoost
## Speed Boost — aumento permanente de velocidad de carrera (+10% por nivel).

const BOOST_POR_NIVEL: float = 0.10


func _init() -> void:
	id          = "speed_boost"
	nombre      = "Speed Boost"
	descripcion = "+10% velocidad de carrera permanente."
	nivel_max   = 5


func aplicar(player: PlayerAgent, _shooting: ShootingSystem) -> void:
	# Modifica la base para que sea permanente y compatible con
	# modificadores temporales (Thunderstorm usa aplicar_modificador_velocidad)
	player.stats["velocidad_base"] *= (1.0 + BOOST_POR_NIVEL)
	player.aplicar_modificador_velocidad(1.0)
