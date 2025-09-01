extends Node2D

@onready var spawner: EnemySpawner = %EnemySpawner
@onready var game_timer: GameTimer = %GameTimer
@onready var level_bar: LevelBar = %LevelBar
@onready var player: Player = %Player
@onready var attack_timer: AttackTimer = %AttackTimer

func _ready() -> void:
	if game_timer:
		game_timer.timer_finished.connect(_on_timer_finished)
	# Connect enemy killed signal to level bar, with fallbacks
	if not level_bar:
		var lb = get_node_or_null("UI/LevelBar") as LevelBar
		if lb:
			level_bar = lb
	if spawner and level_bar:
		spawner.enemy_killed.connect(level_bar.on_enemy_killed)
	# Provide player access to attack cooldown timer if needed
	if player and attack_timer:
		player.set_meta("attack_timer_path", attack_timer.get_path())

func _on_timer_finished() -> void:
	if spawner:
		spawner.stop_spawning()
		spawner.clear_all_enemies()
	# Grant extra auto weapons based on level at wave end
	var level := 0
	if level_bar:
		level = level_bar.get_level()
	if level > 0 and player:
		var weapon_scene := load("res://entities/player/auto_weapon.tscn") as PackedScene
		if weapon_scene:
			for i in range(level):
				var w := weapon_scene.instantiate()
				if w:
					player.add_child(w)
					# Stagger orbit start angles for multiple weapons
					w.orbit_angle = float(i) * (360.0 / float(level))
