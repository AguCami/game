extends Node
## GameManager (Autoload) — Core Game Loop Manager
##
## Controla el estado global y orquesta el flujo principal:
##   Move & Evade -> Gain XP -> Level Up -> Choose Upgrades -> repetir
##   hasta Victoria (gol/boss) o Derrota (resistencia agotada).

# ── Estados globales ───────────────────────────────────────────────────────
enum GameState { EN_PARTIDA, SUBIENDO_NIVEL, PAUSADO, VICTORIA, DERROTA }

var estado: GameState = GameState.EN_PARTIDA

# ── Progresión in-match ────────────────────────────────────────────────────
var nivel_actual: int  = 1
var xp_actual: float   = 0.0
var xp_para_subir: float = 20.0
const XP_CURVA: float  = 1.35   # multiplicador de XP requerida por nivel

# ── Vidas / resistencia de partida ────────────────────────────────────────
var tackles_recibidos: int = 0
const MAX_TACKLES: int = 3

# ── Referencias de escena (inyectadas por GameWorld al iniciar) ───────────
var player: PlayerAgent       = null
var wave_generator: WaveGenerator = null

# ── Señales ───────────────────────────────────────────────────────────────
signal estado_cambiado(nuevo: GameState)
signal xp_actualizada(actual: float, requerida: float)
signal nivel_subido(nivel: int)
signal mostrar_upgrades            # la UI escucha esto y abre UpgradeMenu
signal partida_terminada(victoria: bool)


# ──────────────────────────────────────────────────────────────────────────
# Registro de la partida — llamado por GameWorld._ready()
func registrar_partida(p_player: PlayerAgent, p_waves: WaveGenerator) -> void:
	player         = p_player
	wave_generator = p_waves
	_reset_estado_partida()

	player.xp_ganada.connect(ganar_xp)
	player.player_tackled.connect(_on_player_tackled)
	wave_generator.oleada_completada.connect(_on_oleada_completada)
	wave_generator.boss_derrotado.connect(_on_boss_derrotado)

	_cambiar_estado(GameState.EN_PARTIDA)
	wave_generator.iniciar_siguiente_oleada()


func _reset_estado_partida() -> void:
	nivel_actual      = 1
	xp_actual         = 0.0
	xp_para_subir     = 20.0
	tackles_recibidos = 0


# ── Máquina de estados ────────────────────────────────────────────────────
func _cambiar_estado(nuevo: GameState) -> void:
	if estado == nuevo:
		return
	estado = nuevo
	# Pausa del árbol de escena en menús (el menú usa PROCESS_MODE_ALWAYS)
	get_tree().paused = estado in [GameState.SUBIENDO_NIVEL, GameState.PAUSADO]
	estado_cambiado.emit(estado)


func pausar() -> void:
	if estado == GameState.EN_PARTIDA:
		_cambiar_estado(GameState.PAUSADO)


func reanudar() -> void:
	if estado in [GameState.PAUSADO, GameState.SUBIENDO_NIVEL]:
		_cambiar_estado(GameState.EN_PARTIDA)


# ── Gain XP ───────────────────────────────────────────────────────────────
func ganar_xp(cantidad: float) -> void:
	if estado != GameState.EN_PARTIDA:
		return
	xp_actual += cantidad
	xp_actualizada.emit(xp_actual, xp_para_subir)
	if xp_actual >= xp_para_subir:
		_subir_nivel()


func _subir_nivel() -> void:
	xp_actual -= xp_para_subir
	xp_para_subir *= XP_CURVA
	nivel_actual += 1
	nivel_subido.emit(nivel_actual)
	# Interrumpe el flujo: pausa y pide a la UI el menú de mejoras
	_cambiar_estado(GameState.SUBIENDO_NIVEL)
	mostrar_upgrades.emit()


# Llamado por UpgradeMenu cuando el jugador elige su mejora
func upgrade_elegido() -> void:
	reanudar()


# ── Derrota: demasiados tackles ───────────────────────────────────────────
func _on_player_tackled() -> void:
	tackles_recibidos += 1
	if tackles_recibidos >= MAX_TACKLES:
		_terminar_partida(false)


# ── Avance de oleadas / Victoria ──────────────────────────────────────────
func _on_oleada_completada(_numero: int) -> void:
	if estado == GameState.EN_PARTIDA:
		wave_generator.iniciar_siguiente_oleada()


func _on_boss_derrotado() -> void:
	_terminar_partida(true)


# Llamado por ShootingSystem cuando el balón entra al arco rival
func gol_anotado() -> void:
	ganar_xp(15.0)   # un gol vale mucha XP; la victoria final es el boss


func _terminar_partida(victoria: bool) -> void:
	_cambiar_estado(GameState.VICTORIA if victoria else GameState.DERROTA)
	# Persistir recompensas (Módulo 3 — SaveSystem)
	var monedas: int = nivel_actual * 10 + (50 if victoria else 0)
	SaveSystem.registrar_resultado_partida(monedas, victoria)
	partida_terminada.emit(victoria)
