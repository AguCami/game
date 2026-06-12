extends Node
## SaveSystem (Autoload) — Meta-Progression persistente entre partidas.
##
## Guarda/carga JSON en user:// (en Android se mapea al almacenamiento
## interno privado de la app — no requiere permisos de storage).

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1

# ── Datos persistentes ─────────────────────────────────────────────────────
var datos := {
	"version":             SAVE_VERSION,
	"monedas_ganadas":     0,
	"nivel_carrera":       1,
	"xp_carrera":          0,
	"desbloqueos_estadio": [],     # ids de estadios desbloqueados
	"partidas_jugadas":    0,
	"victorias":           0,
}

const XP_CARRERA_POR_NIVEL: int = 100

signal datos_guardados
signal nivel_carrera_subido(nivel: int)
signal estadio_desbloqueado(id: String)

# ── Catálogo de desbloqueos ───────────────────────────────────────────────
const ESTADIOS := {
	"estadio_barrio":   { "costo": 0,    "nombre": "Potrero del Barrio" },
	"estadio_club":     { "costo": 200,  "nombre": "Cancha del Club" },
	"estadio_mundial":  { "costo": 1000, "nombre": "Estadio Mundialista" },
}


func _ready() -> void:
	cargar()
	# El primer estadio siempre está desbloqueado
	if not datos["desbloqueos_estadio"].has("estadio_barrio"):
		datos["desbloqueos_estadio"].append("estadio_barrio")


# ── Guardado ──────────────────────────────────────────────────────────────
func guardar() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: no se pudo abrir %s (%s)" %
			[SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(datos, "\t"))
	file.close()
	datos_guardados.emit()


# ── Carga ─────────────────────────────────────────────────────────────────
func cargar() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return   # primera ejecución: usar defaults

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: error al leer el guardado")
		return

	var resultado: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if resultado is Dictionary:
		_migrar_si_necesario(resultado)
		# merge conserva claves nuevas que el guardado viejo no tenga
		datos.merge(resultado, true)
	else:
		push_warning("SaveSystem: guardado corrupto, usando defaults")


func _migrar_si_necesario(guardado: Dictionary) -> void:
	# Punto de extensión para migraciones de versión futuras
	var version: int = guardado.get("version", 0)
	if version < SAVE_VERSION:
		guardado["version"] = SAVE_VERSION


# ── API de progresión ─────────────────────────────────────────────────────
func registrar_resultado_partida(monedas: int, victoria: bool) -> void:
	datos["monedas_ganadas"]  += monedas
	datos["partidas_jugadas"] += 1
	if victoria:
		datos["victorias"] += 1
	_ganar_xp_carrera(monedas)   # las monedas también suman XP de carrera
	guardar()


func _ganar_xp_carrera(cantidad: int) -> void:
	datos["xp_carrera"] += cantidad
	var xp_requerida: int = datos["nivel_carrera"] * XP_CARRERA_POR_NIVEL
	while datos["xp_carrera"] >= xp_requerida:
		datos["xp_carrera"] -= xp_requerida
		datos["nivel_carrera"] += 1
		nivel_carrera_subido.emit(datos["nivel_carrera"])
		xp_requerida = datos["nivel_carrera"] * XP_CARRERA_POR_NIVEL


func comprar_estadio(id: String) -> bool:
	if not ESTADIOS.has(id) or datos["desbloqueos_estadio"].has(id):
		return false
	var costo: int = ESTADIOS[id]["costo"]
	if datos["monedas_ganadas"] < costo:
		return false
	datos["monedas_ganadas"] -= costo
	datos["desbloqueos_estadio"].append(id)
	estadio_desbloqueado.emit(id)
	guardar()
	return true


func get_monedas() -> int:
	return datos["monedas_ganadas"]


func get_nivel_carrera() -> int:
	return datos["nivel_carrera"]


func estadio_desbloqueado_check(id: String) -> bool:
	return datos["desbloqueos_estadio"].has(id)


# ── Guardado de emergencia al salir / minimizar (importante en Android) ───
func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		guardar()
