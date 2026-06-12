extends Control
class_name VirtualJoystick
## Joystick virtual táctil (Dual Stick) — versión fija y visible.
## Usa _input() global con detección por rectángulo: robusto en multitouch
## (cada stick rastrea su propio dedo) y no depende del foco de GUI.

enum TipoStick { MOVIMIENTO, APUNTADO }

@export var tipo: TipoStick = TipoStick.MOVIMIENTO
@export var radio_max: float = 130.0
@export var zona_muerta: float = 0.12

var output: Vector2 = Vector2.ZERO
var activo: bool = false

signal direccion_cambiada(dir: Vector2)
signal stick_soltado(ultima_dir: Vector2)

var _touch_index: int = -1
var _centro: Vector2 = Vector2.ZERO

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_centro = base.global_position + base.size / 2.0
	_centrar_knob()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# ¿El toque cae dentro del área de este stick?
			if _touch_index == -1 and get_global_rect().has_point(event.position):
				_touch_index = event.index
				activo = true
				_centro = base.global_position + base.size / 2.0
				_actualizar(event.position)
		elif event.index == _touch_index:
			var ultima: Vector2 = output
			_touch_index = -1
			activo = false
			output = Vector2.ZERO
			_centrar_knob()
			direccion_cambiada.emit(Vector2.ZERO)
			stick_soltado.emit(ultima)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_actualizar(event.position)


func _actualizar(touch_pos: Vector2) -> void:
	var offset: Vector2 = touch_pos - _centro
	var distancia: float = minf(offset.length(), radio_max)
	var dir: Vector2 = offset.normalized() if offset != Vector2.ZERO else Vector2.ZERO
	var magnitud: float = distancia / radio_max
	output = dir * magnitud if magnitud >= zona_muerta else Vector2.ZERO
	knob.position = base.size / 2.0 - knob.size / 2.0 + dir * distancia
	direccion_cambiada.emit(output)


func _centrar_knob() -> void:
	knob.position = base.size / 2.0 - knob.size / 2.0
