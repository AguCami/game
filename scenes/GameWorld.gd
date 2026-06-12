extends Node2D
class_name GameWorld
## Escena de partida: cablea todos los sistemas entre sí.

@onready var player: PlayerAgent          = $PlayerAgent
@onready var wave_generator: WaveGenerator = $WaveGenerator
@onready var shooting: ShootingSystem     = $ShootingSystem
@onready var match_events: MatchEvents    = $MatchEvents
@onready var goal_area: Area2D            = $GoalArea
@onready var hud: HUD                     = $HUD
@onready var upgrade_menu: UpgradeMenu    = $UpgradeMenu


func _ready() -> void:
	var ball: RigidBody2D = player.ball_controller.ball_body

	wave_generator.configurar_referencias(player, ball)
	shooting.configurar(player)
	match_events.configurar(player)
	upgrade_menu.configurar(player, shooting)
	hud.configurar(player, shooting, goal_area, wave_generator, match_events)

	GameManager.registrar_partida(player, wave_generator)
	GameManager.partida_terminada.connect(_on_partida_terminada)


func _on_partida_terminada(victoria: bool) -> void:
	# Placeholder de pantalla final: reinicia la partida tras 3 s
	print("Partida terminada. Victoria: %s" % victoria)
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
