extends CharacterBody2D
class_name EnemyAI

# ── Tipos de comportamiento ────────────────────────────────────────────────
enum Comportamiento { SEEKER, AGRESSOR, MARKER }

# ── Stats ──────────────────────────────────────────────────────────────────
var stats := {
	"velocidad": 180.0,
	"fuerza":    1.0,    # multiplicador de empuje al tacklear
	"radio_tackle": 28.0,
}

var comportamiento: Comportamiento = Comportamiento.SEEKER

# ── Referencias ────────────────────────────────────────────────────────────
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim: AnimatedSprite2D       = $AnimatedSprite2D
@onready var tackle_area: Area2D          = $TackleArea

# Inyectadas por WaveGenerator
var player_ref: PlayerAgent = null
var ball_ref:   RigidBody2D = null

# ── IA interna ────────────────────────────────────────────────────────────
var _ai_timer: float = 0.0
const AI_TICK: float = 0.05   # actualiza ruta cada 50 ms (~20 Hz)

# ── Señales ────────────────────────────────────────────────────────────────
signal enemy_defeated


# ──────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	tackle_area.body_entered.connect(_on_tackle_area_body_entered)
	nav_agent.path_desired_distance    = 8.0
	nav_agent.target_desired_distance  = 16.0


func _physics_process(delta: float) -> void:
	if player_ref == null:
		return

	_ai_timer += delta
	if _ai_timer >= AI_TICK:
		_ai_timer = 0.0
		_recalculate_target()

	_move_along_path(delta)


# ── Selección de objetivo según comportamiento ─────────────────────────────
func _recalculate_target() -> void:
	match comportamiento:
		Comportamiento.SEEKER:
			# Persigue siempre al jugador
			nav_agent.target_position = player_ref.global_position

		Comportamiento.AGRESSOR:
			# Intenta interceptar el balón si está suelto, si no va al jugador
			if ball_ref != null and not player_ref.tiene_balon:
				nav_agent.target_position = ball_ref.global_position
			else:
				nav_agent.target_position = player_ref.global_position

		Comportamiento.MARKER:
			# Se posiciona entre el jugador y la portería (posición anticipada)
			var goal_pos: Vector2 = _get_goal_position()
			var intercept: Vector2 = player_ref.global_position.lerp(goal_pos, 0.4)
			nav_agent.target_position = intercept


# ── Movimiento hacia el siguiente punto de ruta ────────────────────────────
func _move_along_path(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, stats["velocidad"] * 6.0 * delta)
	else:
		var next_pos: Vector2 = nav_agent.get_next_path_position()
		var direction: Vector2 = (next_pos - global_position).normalized()
		velocity = direction * stats["velocidad"]
		if direction.x != 0.0:
			anim.flip_h = direction.x < 0.0
		_play_anim("run")

	move_and_slide()


# ── Tackle al contacto ────────────────────────────────────────────────────
func _on_tackle_area_body_entered(body: Node) -> void:
	if body is PlayerAgent:
		body.recibir_tackle(stats["fuerza"])


# ── Recibir daño / ser eliminado ──────────────────────────────────────────
func ser_eliminado() -> void:
	enemy_defeated.emit()
	queue_free()


# ── Utilidades ───────────────────────────────────────────────────────────
func _get_goal_position() -> Vector2:
	# La portería rival se asume al norte del mapa; WaveGenerator puede sobreescribir
	return Vector2(global_position.x, -2000.0)


func _play_anim(nombre: String) -> void:
	if anim.animation != nombre:
		anim.play(nombre)


# ── Configuración externa (llamada por WaveGenerator) ────────────────────
func configurar(p_comportamiento: Comportamiento, p_stats: Dictionary,
		p_player: PlayerAgent, p_ball: RigidBody2D) -> void:
	comportamiento = p_comportamiento
	stats.merge(p_stats, true)
	player_ref = p_player
	ball_ref   = p_ball
	# Escala visual para el Mega Defender
	if p_stats.get("escala", 1.0) != 1.0:
		scale = Vector2.ONE * p_stats["escala"]
		$TackleArea/CollisionShape2D.shape.radius = stats["radio_tackle"]
