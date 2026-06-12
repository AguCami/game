extends Control
class_name MainMenu
## Menú inicial: título, stats de carrera y botón Jugar.

@onready var monedas_label: Label  = $VBox/StatsBox/MonedasLabel
@onready var carrera_label: Label  = $VBox/StatsBox/CarreraLabel
@onready var record_label: Label   = $VBox/StatsBox/RecordLabel
@onready var jugar_btn: Button     = $VBox/JugarBtn


func _ready() -> void:
	get_tree().paused = false   # por si volvemos de una partida pausada
	jugar_btn.pressed.connect(_on_jugar)
	_actualizar_stats()


func _actualizar_stats() -> void:
	monedas_label.text = "🪙 %d monedas" % SaveSystem.get_monedas()
	carrera_label.text = "Nivel de carrera: %d" % SaveSystem.get_nivel_carrera()
	record_label.text  = "Partidas: %d   Victorias: %d" % [
		SaveSystem.datos["partidas_jugadas"], SaveSystem.datos["victorias"]
	]


func _on_jugar() -> void:
	get_tree().change_scene_to_file("res://scenes/GameWorld.tscn")
