extends Node
## PerformanceManager (Autoload) — Perfil de rendimiento Android.
##
## Reglas de presupuesto por frame que sigue este codebase:
##  - Física a 60 Hz (configurado en project.godot). NO subir a 120:
##    en móvil duplica el costo de CPU sin beneficio visible.
##  - La IA enemiga recalcula rutas a 20 Hz (AI_TICK en EnemyAI.gd),
##    no por frame.
##  - Nada de get_nodes_in_group() ni allocs dentro de _process();
##    solo en eventos (señales, timers).
##  - Los balones extra del multishot se auto-destruyen a los 3 s.
##
## Este nodo añade: FPS adaptativo según el Game Mode / batería.

const FPS_NORMAL: int  = 60
const FPS_AHORRO: int  = 30   # modo batería / app en background

var modo_ahorro: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = FPS_NORMAL
	# V-Sync activado: evita quemar GPU renderizando frames que no se ven
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	_detectar_game_mode()


# ── Game Mode API (Android 12+) ───────────────────────────────────────────
func _detectar_game_mode() -> void:
	if OS.get_name() != "Android":
		return
	# Godot 4.2 no expone GameManager de Android directamente; el modo
	# batería se infiere de low_processor_usage o de un plugin nativo.
	# Hook listo para plugin: si el sistema pide ahorro, activarlo.
	if OS.is_in_low_processor_usage_mode():
		activar_modo_ahorro(true)


func activar_modo_ahorro(activar: bool) -> void:
	modo_ahorro = activar
	Engine.max_fps = FPS_AHORRO if activar else FPS_NORMAL
	# Reduce también la resolución de render en modo ahorro (75%)
	var factor: float = 0.75 if activar else 1.0
	get_viewport().scaling_3d_scale = 1.0   # n/a en 2D, por claridad
	get_window().content_scale_factor = factor


# ── Ahorro automático al ir a background ──────────────────────────────────
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			# La app va a background: Android puede congelarla; bajar todo
			Engine.max_fps = 10
		NOTIFICATION_APPLICATION_RESUMED:
			Engine.max_fps = FPS_AHORRO if modo_ahorro else FPS_NORMAL
