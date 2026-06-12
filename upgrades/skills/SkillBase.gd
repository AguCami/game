extends Resource
class_name SkillBase
## Clase base de todas las habilidades in-match.
## Cada skill define cómo se aplica al jugador y a los sistemas de juego.

@export var id: String = ""
@export var nombre: String = ""
@export var descripcion: String = ""
@export var icono: Texture2D = null
@export var nivel_max: int = 5

var nivel_actual: int = 0


## Sobrescribir en cada skill. Recibe el contexto completo del juego.
func aplicar(_player: PlayerAgent, _shooting: ShootingSystem) -> void:
	push_error("SkillBase.aplicar() debe sobrescribirse en %s" % id)


func puede_subir() -> bool:
	return nivel_actual < nivel_max


func subir_nivel(player: PlayerAgent, shooting: ShootingSystem) -> void:
	if not puede_subir():
		return
	nivel_actual += 1
	aplicar(player, shooting)
