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
@export var health_per_wave_increase: int = 1

var spawn_timer: Timer
var current_enemies: Array[Enemy] = []
var is_active: bool = true
var _play_area_rect: Rect2
signal enemy_killed
var wave_bonus_health: int = 0

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	_cache_play_area_rect()
	
	# Start spawning
	_start_spawn_timer()

	# Spawn initial enemies
	call_deferred("_spawn_initial_enemies")

func _spawn_initial_enemies() -> void:
	if player:
		_spawn_multiple_enemies()

func _start_spawn_timer() -> void:
	if not is_active:
		return
	var random_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.start(random_time)

func _on_spawn_timer_timeout() -> void:
	if not is_active:
		return
	if current_enemies.size() < max_enemies:
		_spawn_multiple_enemies()
	
	_start_spawn_timer()

func _spawn_enemy() -> void:
	if not is_active:
		return
	var enemy_instance = enemy_scene.instantiate() as Enemy
	if not enemy_instance:
		return
	
	# Calculate random spawn position around player
	var spawn_angle = randf() * TAU
	var spawn_distance = randf_range(spawn_radius_min, spawn_radius_max)
	var spawn_offset = Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_distance
	var spawn_position = player.global_position + spawn_offset

	# Clamp to play area bounds if available
	if _play_area_rect and _play_area_rect.size != Vector2.ZERO:
		spawn_position.x = clamp(spawn_position.x, _play_area_rect.position.x, _play_area_rect.position.x + _play_area_rect.size.x)
		spawn_position.y = clamp(spawn_position.y, _play_area_rect.position.y, _play_area_rect.position.y + _play_area_rect.size.y)
	
	enemy_instance.global_position = spawn_position
	# Apply wave-based health bonus
	if wave_bonus_health > 0:
		enemy_instance.max_health += wave_bonus_health * health_per_wave_increase
		enemy_instance.health = enemy_instance.max_health
	enemy_instance.add_to_group("enemies")  # Add to group for weapon detection
	get_parent().add_child(enemy_instance)
	
	# Track the enemy
	current_enemies.append(enemy_instance)
	enemy_instance.enemy_died.connect(_on_enemy_died.bind(enemy_instance))

func _spawn_multiple_enemies() -> void:
	if not is_active:
		return
	# Spawn 2-6 enemies
	var spawn_count = randi_range(2, 6)
	
	for i in range(spawn_count):
		if current_enemies.size() >= max_enemies:
			break  # Stop if we've reached max enemies
		_spawn_enemy()

func _on_enemy_died(enemy: Enemy) -> void:
	current_enemies.erase(enemy)
	enemy_killed.emit()

func get_enemy_count() -> int:
	return current_enemies.size()

func stop_spawning() -> void:
	# Stop the spawn timer
	if spawn_timer:
		spawn_timer.stop()
		print("EnemySpawner: Spawning stopped")
	is_active = false

func clear_all_enemies() -> void:
	# Queue free all tracked enemies
	for enemy in current_enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	# Also clear any remaining nodes in the group as a safety net
	var group_nodes = get_tree().get_nodes_in_group("enemies")
	for node in group_nodes:
		if node is Enemy and is_instance_valid(node):
			node.queue_free()
	current_enemies.clear()
	print("EnemySpawner: Cleared all enemies")

func _cache_play_area_rect() -> void:
	# Try to find sibling Polygon2D named PlayArea and compute its AABB
	var play_area := get_node_or_null("../PlayArea") as Polygon2D
	if play_area and play_area.polygon.size() > 0:
		var min_x := INF
		var min_y := INF
		var max_x := -INF
		var max_y := -INF
		for p in play_area.polygon:
			min_x = min(min_x, p.x)
			min_y = min(min_y, p.y)
			max_x = max(max_x, p.x)
			max_y = max(max_y, p.y)
		_play_area_rect = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	else:
		# Fallback to an empty rect
		_play_area_rect = Rect2()
