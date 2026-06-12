extends Node
## SaveSystem (Autoload) — STUB temporal.
## La implementación completa (JSON local, meta-progression) llega en el
## Módulo 3. Este stub existe para que GameManager compile.

var datos := {
	"monedas_ganadas": 0,
	"nivel_carrera":   1,
	"desbloqueos_estadio": [],
}


func registrar_resultado_partida(monedas: int, _victoria: bool) -> void:
	datos["monedas_ganadas"] += monedas
	# TODO Módulo 3: persistir a disco con FileAccess + JSON
