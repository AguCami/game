extends Control
class_name VirtualJoystick
## Joystick virtual táctil reutilizable (Dual Stick).
## - Stick IZQUIERDO: movimiento del jugador.
## - Stick DERECHO: apuntado de chute/habilidades (emite al soltar).
##
## Multitouch-safe: cada stick rastrea su propio índice de toque, así
## ambos pueden usarse simultáneamente.

enum TipoStick { MOVIMIENTO, APUNTADO }

@export var tipo: TipoStick = TipoStick.MOVIMIENTO
@export var radio_max: float = 110.0      # desplazamiento máx. del knob (px)
@export var zona_muerta: float = 0.15     # 0-1, ignora micro-movimientos
@export var flotante: bool = true          # el stick aparece donde tocas

# ── Salida ─────────────────────────────────────────────────────────────────
var output: Vector2 = Vector2.ZERO        # vector normalizado (-1..1)
var activo: bool = false

signal direccion_cambiada(dir: Vector2)
signal stick_soltado(ultima_dir: Vector2)   # usado por APUNTADO para chutar

# ── Interno ───────────────────────────────────────────────────────────────
var _touch_index: int = -1                # índice del dedo que controla este stick
var _centro: Vector2 = Vector2.ZERO

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob


func _ready() -> void:
	# El HUD debe seguir funcionando aunque cambie el estado del juego,
	# pero los sticks NO durante la pausa real:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if flotante:
		base.visible = false


# Usamos _gui_input para respetar el layout/áreas de Control y que los
# dos sticks no se roben eventos entre sí.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_index == -1:
		# Inicio del toque: capturar este dedo
		_touch_index = event.index
		activo = true
		_centro = event.position if flotante else base.position + base.size / 2.0
		if flotante:
			base.position = _centro - base.size / 2.0
			base.visible = true
		_actualizar_output(event.position)

	elif not event.pressed and event.index == _touch_index:
		# Fin del toque: liberar
		var ultima: Vector2 = output
		_touch_index = -1
		activo = false
		output = Vector2.ZERO
		knob.position = base.size / 2.0 - knob.size / 2.0
		if flotante:
			base.visible = false
		direccion_cambiada.emit(Vector2.ZERO)
		stick_soltado.emit(ultima)


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _touch_index:
		_actualizar_output(event.position)


func _actualizar_output(touch_pos: Vector2) -> void:
	var offset: Vector2 = touch_pos - _centro
	var distancia: float = minf(offset.length(), radio_max)
	var dir: Vector2 = offset.normalized() if offset != Vector2.ZERO else Vector2.ZERO

	# Zona muerta
	var magnitud: float = distancia / radio_max
	output = dir * magnitud if magnitud >= zona_muerta else Vector2.ZERO

	# Posición visual del knob (clampeada al radio)
	knob.position = base.size / 2.0 - knob.size / 2.0 + dir * distancia
	direccion_cambiada.emit(output)
