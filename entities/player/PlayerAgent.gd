extends CharacterBody2D
class_name PlayerAgent

# ── Stats ──────────────────────────────────────────────────────────────────
var stats := {
	"velocidad_base":     300.0,
	"control_balon_base": 0.85,   # 0-1: qué tan pegado orbita el balón
	"resistencia_max":    100.0,
}

# ── Estado ─────────────────────────────────────────────────────────────────
enum Estado { MOVIMIENTO, GAMBETA, CHUTE }
var estado_actual: Estado = Estado.MOVIMIENTO

# ── Habilidades activas ────────────────────────────────────────────────────
var habilidades_activas: Array = []   # se llenan desde UpgradeMenu

# ── Runtime ────────────────────────────────────────────────────────────────
var resistencia_actual: float
var tiene_balon: bool = true
var input_direction: Vector2 = Vector2.ZERO   # inyectado por VirtualJoystick
var velocidad_actual: float                    # permite modificadores externos

# ── Referencias internas ───────────────────────────────────────────────────
@onready var ball_controller: BallController = $BallController
@onready var anim: AnimatedSprite2D           = $AnimatedSprite2D
@onready var gambeta_timer: Timer             = $GambetaTimer
@onready var collision: CollisionShape2D      = $CollisionShape2D

# ── Señales ────────────────────────────────────────────────────────────────
signal xp_ganada(cantidad: float)
signal player_tackled
signal ball_shot(origin: Vector2, direction: Vector2)

# ──────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	resistencia_actual = stats["resistencia_max"]
	velocidad_actual   = stats["velocidad_base"]
	gambeta_timer.wait_time = 0.4
	gambeta_timer.one_shot  = true
	gambeta_timer.timeout.connect(_on_gambeta_end)


func _physics_process(delta: float) -> void:
	match estado_actual:
		Estado.MOVIMIENTO:  _handle_movement(delta)
		Estado.GAMBETA:     _handle_gambeta(delta)
		Estado.CHUTE:       pass   # controlado por ShootingSystem


# ── Movimiento principal ───────────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	if input_direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, velocidad_actual * 8.0 * delta)
		_play_anim("idle")
	else:
		velocity = input_direction.normalized() * velocidad_actual
		_play_anim("run")
		_face_direction(input_direction)

	move_and_slide()
	_check_advance_xp(delta)


# ── Gambeta (dash corto) ───────────────────────────────────────────────────
func iniciar_gambeta() -> void:
	if estado_actual != Estado.MOVIMIENTO:
		return
	estado_actual = Estado.GAMBETA
	gambeta_timer.start()
	_play_anim("gambeta")


func _handle_gambeta(delta: float) -> void:
	velocity = input_direction.normalized() * velocidad_actual * 2.2
	move_and_slide()


func _on_gambeta_end() -> void:
	estado_actual = Estado.MOVIMIENTO


# ── XP por avance ─────────────────────────────────────────────────────────
var _metros_acumulados: float = 0.0

func _check_advance_xp(delta: float) -> void:
	_metros_acumulados += velocity.length() * delta * 0.01
	if _metros_acumulados >= 1.0:
		_metros_acumulados -= 1.0
		xp_ganada.emit(1.0)


# ── Recibir tackle ────────────────────────────────────────────────────────
func recibir_tackle(fuerza: float) -> void:
	if estado_actual == Estado.GAMBETA:
		return   # invulnerable durante gambeta
	tiene_balon = false
	ball_controller.soltar_balon()
	player_tackled.emit()
	velocity = -input_direction.normalized() * fuerza * 200.0


# ── Recuperar balón ────────────────────────────────────────────────────────
func recuperar_balon() -> void:
	tiene_balon = true
	ball_controller.agarrar_balon()


# ── Utilidades ────────────────────────────────────────────────────────────
func aplicar_modificador_velocidad(multiplicador: float) -> void:
	velocidad_actual = stats["velocidad_base"] * multiplicador


func _face_direction(dir: Vector2) -> void:
	if dir.x != 0.0:
		anim.flip_h = dir.x < 0.0


func _play_anim(nombre: String) -> void:
	if anim.animation != nombre:
		anim.play(nombre)
