class_name EnemySpawner
extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval_min: float = 2.0
@export var spawn_interval_max: float = 5.0
@export var max_enemies: int = 10
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
	for i in range(initial_enemies):
		if player:
			_spawn_enemy()

func _start_spawn_timer() -> void:
	var random_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.start(random_time)

func _on_spawn_timer_timeout() -> void:
	if current_enemies.size() < max_enemies:
		_spawn_enemy()
	
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
	get_parent().add_child(enemy_instance)
	
	# Track the enemy
	current_enemies.append(enemy_instance)
	enemy_instance.enemy_died.connect(_on_enemy_died.bind(enemy_instance))

func _on_enemy_died(enemy: Enemy) -> void:
	current_enemies.erase(enemy)

func get_enemy_count() -> int:
	return current_enemies.size()
