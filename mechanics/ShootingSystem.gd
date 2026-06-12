extends Node2D
class_name ShootingSystem
## Shooting & Passing — disparo semiautomático con Auto-Aim al arco rival.
##
## Modos:
##  - AUTO: chuta solo cuando hay línea despejada al arco y cooldown listo.
##  - SEMI: el jugador pulsa el botón/stick derecho; el sistema corrige
##    la dirección hacia el mejor objetivo (Auto-Aim Target).

enum Modo { AUTO, SEMI }

@export var modo: Modo = Modo.SEMI
@export var goal_target_path: NodePath        # Area2D del arco rival
@export var shoot_cooldown: float = 1.2
@export var auto_aim_angle_deg: float = 35.0  # cono de corrección en modo SEMI
@export var rango_auto_chute: float = 520.0   # distancia máx. para chute AUTO

var player: PlayerAgent = null
var _cooldown_restante: float = 0.0
var _multishot_count: int = 1                 # modificado por MultiShotBall

@onready var goal_target: Area2D = get_node_or_null(goal_target_path)

signal chute_realizado(direccion: Vector2)
signal gol


func configurar(p_player: PlayerAgent) -> void:
	player = p_player
	if goal_target != null:
		goal_target.body_entered.connect(_on_goal_body_entered)


func _physics_process(delta: float) -> void:
	if player == null or not player.tiene_balon:
		return
	_cooldown_restante = maxf(0.0, _cooldown_restante - delta)

	if modo == Modo.AUTO and _cooldown_restante <= 0.0:
		_intentar_auto_chute()


# ── Modo AUTO ─────────────────────────────────────────────────────────────
func _intentar_auto_chute() -> void:
	if goal_target == null:
		return
	var to_goal: Vector2 = goal_target.global_position - player.global_position
	if to_goal.length() > rango_auto_chute:
		return
	if _linea_despejada(to_goal):
		ejecutar_chute(to_goal.normalized())


func _linea_despejada(to_goal: Vector2) -> bool:
	var space := player.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + to_goal
	)
	query.collision_mask = 0b10   # capa 2 = enemigos
	query.exclude = [player.get_rid()]
	return space.intersect_ray(query).is_empty()


# ── Modo SEMI — llamado por la UI (stick derecho / botón) ─────────────────
func chute_manual(direccion_input: Vector2) -> void:
	if player == null or not player.tiene_balon or _cooldown_restante > 0.0:
		return
	ejecutar_chute(_aplicar_auto_aim(direccion_input))


func _aplicar_auto_aim(dir: Vector2) -> Vector2:
	# Corrige hacia el arco si el input está dentro del cono de auto-aim
	if goal_target == null or dir == Vector2.ZERO:
		return dir.normalized() if dir != Vector2.ZERO else Vector2.UP
	var to_goal: Vector2 = (goal_target.global_position - player.global_position).normalized()
	if rad_to_deg(absf(dir.angle_to(to_goal))) <= auto_aim_angle_deg:
		return to_goal
	return dir.normalized()


# ── Ejecución del chute (con soporte multishot) ───────────────────────────
func ejecutar_chute(direccion: Vector2) -> void:
	_cooldown_restante = shoot_cooldown
	player.estado_actual = PlayerAgent.Estado.CHUTE

	# Balón principal
	player.ball_controller.chutar(direccion)

	# Balones extra (Multi-Shot Ball) con abanico de ±12°
	for i in range(1, _multishot_count):
		var spread: float = deg_to_rad(12.0) * ceilf(i / 2.0) * (1 if i % 2 == 1 else -1)
		_spawn_balon_extra(direccion.rotated(spread))

	player.estado_actual = PlayerAgent.Estado.MOVIMIENTO
	chute_realizado.emit(direccion)


func _spawn_balon_extra(direccion: Vector2) -> void:
	var extra := RigidBody2D.new()
	extra.gravity_scale = 0.0
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 10.0
	extra.add_child(shape)
	get_parent().add_child(extra)
	extra.global_position = player.ball_controller.get_ball_global_pos()
	extra.linear_velocity = direccion * BallController.SHOOT_SPEED
	# Auto-destruir a los 3 s para no acumular cuerpos
	get_tree().create_timer(3.0).timeout.connect(extra.queue_free)


func set_multishot(count: int) -> void:
	_multishot_count = maxi(1, count)


# ── Detección de gol ──────────────────────────────────────────────────────
func _on_goal_body_entered(body: Node) -> void:
	if body is RigidBody2D:   # cualquier balón
		gol.emit()
		GameManager.gol_anotado()
		player.recuperar_balon()
