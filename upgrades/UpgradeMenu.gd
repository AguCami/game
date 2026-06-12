extends CanvasLayer
class_name UpgradeMenu
## Menú de mejoras in-match: al subir de nivel ofrece 3 skills aleatorias.
## Funciona con el árbol pausado (PROCESS_MODE_ALWAYS).

# ── Pool de skills disponibles ─────────────────────────────────────────────
var pool_skills: Array[SkillBase] = []

# ── Referencias (inyectadas por GameWorld) ─────────────────────────────────
var player: PlayerAgent       = null
var shooting: ShootingSystem  = null

# ── UI ─────────────────────────────────────────────────────────────────────
@onready var panel: Control            = $Panel
@onready var opciones_container: HBoxContainer = $Panel/OpcionesContainer

const NUM_OPCIONES: int = 3

signal skill_elegida(skill: SkillBase)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona durante la pausa
	panel.visible = false
	_inicializar_pool()
	GameManager.mostrar_upgrades.connect(abrir)


func configurar(p_player: PlayerAgent, p_shooting: ShootingSystem) -> void:
	player   = p_player
	shooting = p_shooting


func _inicializar_pool() -> void:
	pool_skills = [
		MultiShotBall.new(),
		SpeedBoost.new(),
		ForceField.new(),
	]


# ── Apertura: elegir 3 opciones aleatorias válidas ─────────────────────────
func abrir() -> void:
	var candidatas: Array[SkillBase] = []
	for skill in pool_skills:
		if skill.puede_subir():
			candidatas.append(skill)

	if candidatas.is_empty():
		# Todas las skills al máximo: dar XP de consuelo y reanudar
		GameManager.upgrade_elegido()
		return

	candidatas.shuffle()
	var opciones: Array[SkillBase] = candidatas.slice(0, NUM_OPCIONES)
	_construir_botones(opciones)
	panel.visible = true


func _construir_botones(opciones: Array[SkillBase]) -> void:
	for child in opciones_container.get_children():
		child.queue_free()

	for skill in opciones:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(280, 360)
		btn.text = "%s\nNv. %d → %d\n\n%s" % [
			skill.nombre, skill.nivel_actual, skill.nivel_actual + 1, skill.descripcion
		]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.pressed.connect(_on_skill_seleccionada.bind(skill))
		opciones_container.add_child(btn)


# ── Selección ─────────────────────────────────────────────────────────────
func _on_skill_seleccionada(skill: SkillBase) -> void:
	skill.subir_nivel(player, shooting)
	if not player.habilidades_activas.has(skill):
		player.habilidades_activas.append(skill)
	skill_elegida.emit(skill)
	panel.visible = false
	GameManager.upgrade_elegido()   # reanuda la partida
