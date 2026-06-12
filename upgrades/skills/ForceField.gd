extends SkillBase
class_name ForceField
## Force Field — escudo periódico que repele defensas cercanos.
## Cada nivel: +radio y -cooldown.

const RADIO_BASE: float       = 120.0
const RADIO_POR_NIVEL: float  = 30.0
const COOLDOWN_BASE: float    = 10.0
const COOLDOWN_POR_NIVEL: float = 1.5
const DURACION: float         = 3.0
const FUERZA_REPULSION: float = 600.0

var _player: PlayerAgent = null
var _timer: Timer = null
var _activo: bool = false


func _init() -> void:
	id          = "force_field"
	nombre      = "Force Field"
	descripcion = "Escudo temporal que repele defensas."
	nivel_max   = 4


func aplicar(player: PlayerAgent, _shooting: ShootingSystem) -> void:
	_player = player
	if _timer == null:
		# Primer nivel: crear el ciclo de activación
		_timer = Timer.new()
		_timer.one_shot = false
		player.add_child(_timer)
		_timer.timeout.connect(_activar_escudo)
	_timer.wait_time = maxf(3.0, COOLDOWN_BASE - COOLDOWN_POR_NIVEL * nivel_actual)
	_timer.start()


func _activar_escudo() -> void:
	if _activo or not is_instance_valid(_player):
		return
	_activo = true
	var radio: float = RADIO_BASE + RADIO_POR_NIVEL * (nivel_actual - 1)

	# Repulsión periódica durante la duración del escudo
	var ticks: int = int(DURACION / 0.2)
	for i in ticks:
		_repeler_enemigos(radio)
		await _player.get_tree().create_timer(0.2).timeout
	_activo = false


func _repeler_enemigos(radio: float) -> void:
	if not is_instance_valid(_player):
		return
	for enemy in _player.get_tree().get_nodes_in_group("enemies"):
		var offset: Vector2 = enemy.global_position - _player.global_position
		if offset.length() <= radio:
			enemy.velocity = offset.normalized() * FUERZA_REPULSION
			enemy.move_and_slide()


## El escudo activo también bloquea tackles: PlayerAgent puede consultarlo.
func esta_activo() -> bool:
	return _activo
