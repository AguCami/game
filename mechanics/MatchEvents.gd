extends Node
class_name MatchEvents
## Eventos de Partida — sucesos aleatorios que alteran el match.
##
## Eventos implementados:
##  - RED_CARD_CHECK: si un rival tacklea con fuerza alta, chance de tarjeta
##    roja → el enemigo es expulsado (eliminado).
##  - THUNDERSTORM: tormenta temporal que reduce la tracción (control del
##    balón y velocidad de todos los agentes).

enum TipoEvento { RED_CARD_CHECK, THUNDERSTORM }

# ── Configuración ─────────────────────────────────────────────────────────
@export var intervalo_eventos: Vector2 = Vector2(15.0, 30.0)  # rango en s
@export var prob_tarjeta_roja: float = 0.35   # al evaluar un tackle fuerte
@export var umbral_fuerza_falta: float = 1.5  # fuerza mínima para considerar falta
@export var duracion_tormenta: float = 8.0
@export var penalizacion_tormenta: float = 0.65  # multiplicador de tracción

var tormenta_activa: bool = false
var _event_timer: Timer

var player: PlayerAgent = null

signal evento_iniciado(tipo: TipoEvento)
signal evento_terminado(tipo: TipoEvento)
signal tarjeta_roja(enemigo: EnemyAI)


func _ready() -> void:
	_event_timer = Timer.new()
	_event_timer.one_shot = true
	add_child(_event_timer)
	_event_timer.timeout.connect(_lanzar_evento_aleatorio)
	_programar_siguiente_evento()


func configurar(p_player: PlayerAgent) -> void:
	player = p_player


func _programar_siguiente_evento() -> void:
	_event_timer.start(randf_range(intervalo_eventos.x, intervalo_eventos.y))


# ── Lanzador aleatorio ────────────────────────────────────────────────────
func _lanzar_evento_aleatorio() -> void:
	if GameManager.estado != GameManager.GameState.EN_PARTIDA:
		_programar_siguiente_evento()
		return
	# Por ahora el único evento temporizado es la tormenta;
	# RedCardCheck se dispara por tackles (ver red_card_check()).
	_iniciar_tormenta()
	_programar_siguiente_evento()


# ── THUNDERSTORM ──────────────────────────────────────────────────────────
func _iniciar_tormenta() -> void:
	if tormenta_activa:
		return
	tormenta_activa = true
	evento_iniciado.emit(TipoEvento.THUNDERSTORM)

	# Penaliza tracción del jugador y de todos los enemigos vivos
	if player != null:
		player.aplicar_modificador_velocidad(penalizacion_tormenta)
		player.stats["control_balon_base"] *= penalizacion_tormenta
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.stats["velocidad"] *= penalizacion_tormenta

	get_tree().create_timer(duracion_tormenta).timeout.connect(_terminar_tormenta)


func _terminar_tormenta() -> void:
	tormenta_activa = false
	if player != null:
		player.aplicar_modificador_velocidad(1.0)
		player.stats["control_balon_base"] /= penalizacion_tormenta
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.stats["velocidad"] /= penalizacion_tormenta
	evento_terminado.emit(TipoEvento.THUNDERSTORM)


# ── RED_CARD_CHECK ────────────────────────────────────────────────────────
## Llamar desde EnemyAI tras un tackle: si la fuerza supera el umbral,
## hay chance de expulsión inmediata del agresor.
func red_card_check(enemigo: EnemyAI) -> void:
	if enemigo.stats["fuerza"] < umbral_fuerza_falta:
		return
	if randf() <= prob_tarjeta_roja:
		evento_iniciado.emit(TipoEvento.RED_CARD_CHECK)
		tarjeta_roja.emit(enemigo)
		enemigo.ser_eliminado()
