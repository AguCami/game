extends CanvasLayer
class_name UpgradeMenu
## Menú de mejoras in-match: al subir de nivel ofrece 3 skills aleatorias.
## Funciona con el árbol pausado (PROCESS_MODE_ALWAYS).

var pool_skills: Array = []
var player: PlayerAgent       = null
var shooting: ShootingSystem  = null

@onready var panel: Control                    = $Panel
@onready var opciones_container: HBoxContainer = $Panel/OpcionesContainer

const NUM_OPCIONES: int = 3

signal skill_elegida(skill: SkillBase)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	pool_skills = [MultiShotBall.new(), SpeedBoost.new(), ForceField.new()]
	GameManager.mostrar_upgrades.connect(abrir)


func configurar(p_player: PlayerAgent, p_shooting: ShootingSystem) -> void:
	player   = p_player
	shooting = p_shooting


func abrir() -> void:
	var candidatas: Array = pool_skills.filter(func(s): return s.puede_subir())
	if candidatas.is_empty():
		GameManager.upgrade_elegido()
		return
	candidatas.shuffle()
	_construir_botones(candidatas.slice(0, NUM_OPCIONES))
	panel.visible = true


func _construir_botones(opciones: Array) -> void:
	for child in opciones_container.get_children():
		child.queue_free()

	for skill in opciones:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(300, 380)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_skill_seleccionada.bind(skill))

		# Contenido como Label hijo: permite autowrap (Button no lo soporta en 4.2)
		var lbl := Label.new()
		lbl.text = "%s\n\nNv. %d → %d\n\n%s" % [
			skill.nombre, skill.nivel_actual, skill.nivel_actual + 1, skill.descripcion
		]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.offset_left = 14.0
		lbl.offset_right = -14.0
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 30)
		btn.add_child(lbl)

		opciones_container.add_child(btn)


func _on_skill_seleccionada(skill: SkillBase) -> void:
	skill.subir_nivel(player, shooting)
	if player != null and not player.habilidades_activas.has(skill):
		player.habilidades_activas.append(skill)
	skill_elegida.emit(skill)
	panel.visible = false
	GameManager.upgrade_elegido()
