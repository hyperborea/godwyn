class_name EnemySpawner
extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval_min: float = 5.0
@export var spawn_interval_max: float = 8.0
@export var max_enemies: int = 30
@export var initial_enemies: int = 3
@export var spawn_radius_min: float = 300.0
@export var spawn_radius_max: float = 600.0
@export var player: Player

var spawn_timer: Timer
var current_enemies: Array[Enemy] = []

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Start spawning
	_start_spawn_timer()

	# Spawn initial enemies
	call_deferred("_spawn_initial_enemies")

func _spawn_initial_enemies() -> void:
	if player:
		_spawn_multiple_enemies()

func _start_spawn_timer() -> void:
	var random_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.start(random_time)

func _on_spawn_timer_timeout() -> void:
	if current_enemies.size() < max_enemies:
		_spawn_multiple_enemies()
	
	_start_spawn_timer()

func _spawn_enemy() -> void:
	var enemy_instance = enemy_scene.instantiate() as Enemy
	if not enemy_instance:
		return
	
	# Calculate random spawn position around player
	var spawn_angle = randf() * TAU
	var spawn_distance = randf_range(spawn_radius_min, spawn_radius_max)
	var spawn_offset = Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_distance
	var spawn_position = player.global_position + spawn_offset
	
	enemy_instance.global_position = spawn_position
	enemy_instance.add_to_group("enemies")  # Add to group for weapon detection
	get_parent().add_child(enemy_instance)
	
	# Track the enemy
	current_enemies.append(enemy_instance)
	enemy_instance.enemy_died.connect(_on_enemy_died.bind(enemy_instance))

func _spawn_multiple_enemies() -> void:
	# Spawn 2-6 enemies
	var spawn_count = randi_range(2, 6)
	
	for i in range(spawn_count):
		if current_enemies.size() >= max_enemies:
			break  # Stop if we've reached max enemies
		_spawn_enemy()

func _on_enemy_died(enemy: Enemy) -> void:
	current_enemies.erase(enemy)

func get_enemy_count() -> int:
	return current_enemies.size()

func stop_spawning() -> void:
	# Stop the spawn timer
	if spawn_timer:
		spawn_timer.stop()
		print("EnemySpawner: Spawning stopped")
