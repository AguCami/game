extends Node
class_name WaveGenerator

# ── Recursos ───────────────────────────────────────────────────────────────
@export var enemy_scene: PackedScene          # EnemyAI.tscn
@export var spawn_area: Rect2 = Rect2(-600, -600, 1200, 1200)
@export var spawn_margin: float = 120.0       # mínima distancia al jugador

# ── Estado de oleadas ──────────────────────────────────────────────────────
var oleada_actual: int   = 0
var enemigos_vivos: int  = 0
var oleada_activa: bool  = false

# ── Referencias ────────────────────────────────────────────────────────────
var player_ref: PlayerAgent = null
var ball_ref:   RigidBody2D = null

# ── Señales ───────────────────────────────────────────────────────────────
signal oleada_completada(numero: int)
signal boss_derrotado
signal todos_enemigos_muertos

# ── Definición de oleadas ─────────────────────────────────────────────────
# Cada entrada: { comportamiento, stats_override, cantidad }
const OLEADAS: Array = [
	# Oleada 1 – Peons (Seekers lentos)
	[
		{
			"comportamiento": EnemyAI.Comportamiento.SEEKER,
			"cantidad": 4,
			"stats": { "velocidad": 140.0, "fuerza": 0.7, "radio_tackle": 24.0 }
		}
	],
	# Oleada 2 – Fast (Agressors rápidos)
	[
		{
			"comportamiento": EnemyAI.Comportamiento.AGRESSOR,
			"cantidad": 5,
			"stats": { "velocidad": 240.0, "fuerza": 1.0, "radio_tackle": 26.0 }
		},
		{
			"comportamiento": EnemyAI.Comportamiento.MARKER,
			"cantidad": 2,
			"stats": { "velocidad": 160.0, "fuerza": 0.8, "radio_tackle": 28.0 }
		}
	],
	# Oleada 3 – Mix
	[
		{
			"comportamiento": EnemyAI.Comportamiento.SEEKER,
			"cantidad": 4,
			"stats": { "velocidad": 170.0, "fuerza": 0.9, "radio_tackle": 24.0 }
		},
		{
			"comportamiento": EnemyAI.Comportamiento.AGRESSOR,
			"cantidad": 4,
			"stats": { "velocidad": 250.0, "fuerza": 1.1, "radio_tackle": 26.0 }
		}
	],
]

# Oleada Boss – un solo Mega Defender gigante + escoltas
const OLEADA_BOSS: Array = [
	{
		"comportamiento": EnemyAI.Comportamiento.SEEKER,
		"cantidad": 1,
		"stats": {
			"velocidad": 120.0,
			"fuerza":    3.0,
			"radio_tackle": 64.0,
			"escala":    2.2   # visual + hitbox grande
		},
		"es_boss": true
	},
	{
		"comportamiento": EnemyAI.Comportamiento.AGRESSOR,
		"cantidad": 3,
		"stats": { "velocidad": 200.0, "fuerza": 1.0, "radio_tackle": 26.0 }
	}
]

const OLEADA_BOSS_INDICE: int = 4   # la boss ocurre en la oleada 5


# ──────────────────────────────────────────────────────────────────────────
func iniciar_siguiente_oleada() -> void:
	oleada_actual  += 1
	oleada_activa   = true
	enemigos_vivos  = 0

	var definicion: Array = _get_definicion_oleada(oleada_actual)
	for grupo in definicion:
		_spawnear_grupo(grupo)


func _get_definicion_oleada(numero: int) -> Array:
	if numero == OLEADA_BOSS_INDICE:
		return OLEADA_BOSS
	# Recicla las oleadas normales con dificultad escalada
	var idx: int = (numero - 1) % OLEADAS.size()
	return _escalar_dificultad(OLEADAS[idx], numero)


func _escalar_dificultad(definicion: Array, numero: int) -> Array:
	var factor: float = 1.0 + (numero - 1) * 0.15
	var resultado: Array = []
	for grupo in definicion:
		var g: Dictionary = grupo.duplicate(true)
		g["stats"]["velocidad"]    = g["stats"].get("velocidad", 150.0) * factor
		g["stats"]["fuerza"]       = g["stats"].get("fuerza", 1.0) * factor
		g["cantidad"]              = int(g["cantidad"] * (1.0 + (numero - 1) * 0.2))
		resultado.append(g)
	return resultado


# ── Spawn de un grupo ─────────────────────────────────────────────────────
func _spawnear_grupo(grupo: Dictionary) -> void:
	for i in grupo["cantidad"]:
		var enemy: EnemyAI = enemy_scene.instantiate() as EnemyAI
		get_parent().add_child(enemy)
		enemy.global_position = _posicion_spawn_valida()
		enemy.configurar(
			grupo["comportamiento"],
			grupo["stats"],
			player_ref,
			ball_ref
		)
		enemy.enemy_defeated.connect(_on_enemy_defeated.bind(grupo.get("es_boss", false)))
		enemigos_vivos += 1


# ── Posición aleatoria fuera del área visible pero dentro del mapa ─────────
func _posicion_spawn_valida() -> Vector2:
	var intentos: int = 0
	while intentos < 20:
		var pos := Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		if player_ref == null or pos.distance_to(player_ref.global_position) >= spawn_margin:
			return pos
		intentos += 1
	return spawn_area.get_center() + Vector2(spawn_margin, 0.0)


# ── Callback: enemigo muerto ──────────────────────────────────────────────
func _on_enemy_defeated(es_boss: bool) -> void:
	enemigos_vivos -= 1
	if es_boss:
		boss_derrotado.emit()

	if enemigos_vivos <= 0:
		oleada_activa = false
		oleada_completada.emit(oleada_actual)
		todos_enemigos_muertos.emit()


# ── Configuración externa ─────────────────────────────────────────────────
func configurar_referencias(p_player: PlayerAgent, p_ball: RigidBody2D) -> void:
	player_ref = p_player
	ball_ref   = p_ball
