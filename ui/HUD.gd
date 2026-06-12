extends CanvasLayer
class_name HUD
## HUD principal: XPBar, GoalArrow, SkillSlots y Dual Virtual Stick.
## Conecta los sticks con PlayerAgent (movimiento) y ShootingSystem (chute).

# ── Referencias de escena ──────────────────────────────────────────────────
@onready var xp_bar: ProgressBar          = $XPBar
@onready var nivel_label: Label           = $XPBar/NivelLabel
@onready var goal_arrow: TextureRect      = $GoalArrow
@onready var skill_slots: HBoxContainer   = $SkillSlots
@onready var stick_izq: VirtualJoystick   = $StickIzquierdo
@onready var stick_der: VirtualJoystick   = $StickDerecho
@onready var oleada_label: Label          = $OleadaLabel
@onready var evento_label: Label          = $EventoLabel

# ── Inyectadas por GameWorld ───────────────────────────────────────────────
var player: PlayerAgent      = null
var shooting: ShootingSystem = null
var goal_node: Node2D        = null     # arco rival, para la GoalArrow

const MAX_SKILL_SLOTS: int = 6


func _ready() -> void:
	GameManager.xp_actualizada.connect(_on_xp_actualizada)
	GameManager.nivel_subido.connect(_on_nivel_subido)
	evento_label.visible = false


## Conexión de los sistemas de juego — llamada por GameWorld._ready()
func configurar(p_player: PlayerAgent, p_shooting: ShootingSystem,
		p_goal: Node2D, p_waves: WaveGenerator, p_events: MatchEvents) -> void:
	player    = p_player
	shooting  = p_shooting
	goal_node = p_goal

	# Stick izquierdo → movimiento continuo
	stick_izq.direccion_cambiada.connect(_on_mover)
	# Stick derecho → apuntar y chutar al soltar
	stick_der.stick_soltado.connect(_on_chutar)

	p_waves.oleada_completada.connect(_on_oleada_completada)
	p_events.evento_iniciado.connect(_on_evento_iniciado)
	p_events.evento_terminado.connect(_on_evento_terminado)


# ── Dual Stick ────────────────────────────────────────────────────────────
func _on_mover(dir: Vector2) -> void:
	if player != null:
		player.input_direction = dir


func _on_chutar(dir: Vector2) -> void:
	if shooting != null and dir.length() > 0.3:   # evita chutes accidentales
		shooting.chute_manual(dir)


# ── XPBar ─────────────────────────────────────────────────────────────────
func _on_xp_actualizada(actual: float, requerida: float) -> void:
	xp_bar.max_value = requerida
	xp_bar.value     = actual


func _on_nivel_subido(nivel: int) -> void:
	nivel_label.text = "Nv. %d" % nivel
	xp_bar.value = 0.0


# ── GoalArrow: flecha que apunta al arco rival ────────────────────────────
# Solo rota un TextureRect — costo por frame despreciable.
func _process(_delta: float) -> void:
	if player == null or goal_node == null:
		return
	var to_goal: Vector2 = goal_node.global_position - player.global_position
	goal_arrow.rotation = to_goal.angle() + PI / 2.0
	# Oculta la flecha cuando el arco ya está cerca/visible
	goal_arrow.visible = to_goal.length() > 600.0


# ── SkillSlots: iconos de habilidades activas ─────────────────────────────
func actualizar_skill_slots() -> void:
	for child in skill_slots.get_children():
		child.queue_free()
	if player == null:
		return
	for skill in player.habilidades_activas.slice(0, MAX_SKILL_SLOTS):
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(72, 72)
		slot.texture = skill.icono
		slot.tooltip_text = "%s Nv.%d" % [skill.nombre, skill.nivel_actual]
		skill_slots.add_child(slot)


# ── Feedback de oleadas y eventos ─────────────────────────────────────────
func _on_oleada_completada(numero: int) -> void:
	oleada_label.text = "Oleada %d superada!" % numero


func _on_evento_iniciado(tipo: MatchEvents.TipoEvento) -> void:
	match tipo:
		MatchEvents.TipoEvento.THUNDERSTORM:
			evento_label.text = "⛈ ¡Tormenta! Tracción reducida"
		MatchEvents.TipoEvento.RED_CARD_CHECK:
			evento_label.text = "🟥 ¡Tarjeta roja!"
	evento_label.visible = true


func _on_evento_terminado(_tipo: MatchEvents.TipoEvento) -> void:
	evento_label.visible = false
