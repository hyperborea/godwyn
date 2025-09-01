extends Node2D

@onready var spawner: EnemySpawner = %EnemySpawner
@onready var game_timer: GameTimer = %GameTimer

func _ready() -> void:
	if game_timer:
		game_timer.timer_finished.connect(_on_timer_finished)

func _on_timer_finished() -> void:
	if spawner:
		spawner.stop_spawning()
		spawner.clear_all_enemies()
