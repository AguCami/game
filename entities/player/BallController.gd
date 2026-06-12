extends Node2D
class_name BallController

# ── Configuración de órbita ────────────────────────────────────────────────
const ORBIT_RADIUS:    float = 48.0   # px desde el centro del jugador
const ORBIT_LERP:      float = 12.0   # suavidad de seguimiento
const SHOOT_SPEED:     float = 900.0
const RETURN_DISTANCE: float = 36.0   # distancia para auto-recuperar

# ── Estado ─────────────────────────────────────────────────────────────────
var activo: bool = true               # el jugador tiene el balón
var angulo_orbita: float = 0.0       # ángulo actual de la órbita (radianes)

# ── Referencias ────────────────────────────────────────────────────────────
@onready var ball_body: RigidBody2D  = $BallBody
@onready var player: PlayerAgent     = get_parent() as PlayerAgent

# Objetivo de posición de órbita calculado cada frame
var _target_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	ball_body.freeze = true   # empieza en modo cinemático (orbita)


func _physics_process(delta: float) -> void:
	if activo:
		_update_orbit(delta)
	else:
		_check_auto_recover()


# ── Órbita suave ──────────────────────────────────────────────────────────
func _update_orbit(delta: float) -> void:
	var input_dir: Vector2 = player.input_direction

	# El balón se desplaza al frente del jugador según la dirección de movimiento
	if input_dir.length() > 0.1:
		var target_angle: float = input_dir.angle()
		# Rotación suave del ángulo de órbita
		angulo_orbita = lerp_angle(angulo_orbita, target_angle, ORBIT_LERP * delta)
	# Si el jugador está quieto el balón mantiene posición anterior

	var control: float = player.stats["control_balon_base"]
	_target_pos = player.global_position + Vector2.from_angle(angulo_orbita) * ORBIT_RADIUS

	# lerp con el factor de control del jugador (mejoras lo incrementan)
	ball_body.global_position = ball_body.global_position.lerp(
		_target_pos, ORBIT_LERP * control * delta
	)


# ── Auto-recuperar si el balón está cerca ─────────────────────────────────
func _check_auto_recover() -> void:
	if ball_body.global_position.distance_to(player.global_position) <= RETURN_DISTANCE:
		agarrar_balon()


# ── API pública ───────────────────────────────────────────────────────────
func agarrar_balon() -> void:
	activo = true
	ball_body.freeze         = true
	ball_body.linear_velocity = Vector2.ZERO
	player.tiene_balon        = true


func soltar_balon() -> void:
	activo = false
	ball_body.freeze = false
	# El balón sale disparado levemente en la dirección opuesta al tackle
	ball_body.linear_velocity = -player.velocity.normalized() * 180.0


func chutar(direccion: Vector2, speed_multiplier: float = 1.0) -> void:
	activo = false
	player.tiene_balon = false
	ball_body.freeze          = false
	ball_body.linear_velocity = direccion.normalized() * SHOOT_SPEED * speed_multiplier
	player.ball_shot.emit(ball_body.global_position, direccion)


# Llamado desde habilidad MultiShotBall — devuelve posición actual del balón
func get_ball_global_pos() -> Vector2:
	return ball_body.global_position
