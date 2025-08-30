class_name AutoWeapon
extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 2.0  # Time between shots in seconds
@export var bullet_speed: float = 600.0
@export var bullet_damage: int = 1
@export var detection_radius: float = 500.0
@export var orbit_speed: float = 90.0  # Degrees per second
@export var orbit_distance: float = 80.0  # Distance from player center

var fire_timer: float = 0.0
var orbit_angle: float = 0.0
var player: Player
var enemies: Array[Enemy] = []

func _ready() -> void:
	# Find the player
	player = get_parent() as Player
	if not player:
		# Try to find player in the scene tree
		player = get_node("/root/World/Player")
	
	# Set initial position
	update_orbit_position()

func _process(delta: float) -> void:
	if not player:
		return
	
	# Update orbit position
	orbit_angle += orbit_speed * delta
	update_orbit_position()
	
	# Update fire timer
	fire_timer -= delta
	
	# Find enemies and shoot if timer is ready
	if fire_timer <= 0.0:
		find_enemies()
		if enemies.size() > 0:
			shoot_at_closest_enemy()
			fire_timer = fire_rate

func update_orbit_position() -> void:
	if not player:
		return
	
	var angle_rad = deg_to_rad(orbit_angle)
	var offset = Vector2(cos(angle_rad), sin(angle_rad)) * orbit_distance
	global_position = player.global_position + offset

func find_enemies() -> void:
	enemies.clear()
	
	# Get all enemies in the scene
	var enemy_nodes = get_tree().get_nodes_in_group("enemies")
	
	# Filter enemies within detection range
	for enemy in enemy_nodes:
		if enemy is Enemy and enemy.global_position.distance_to(global_position) <= detection_radius:
			enemies.append(enemy)

func shoot_at_closest_enemy() -> void:
	if enemies.size() == 0 or not bullet_scene:
		return
	
	# Find closest enemy
	var closest_enemy: Enemy = null
	var closest_distance = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	if not closest_enemy:
		return
	
	# Create bullet
	var bullet = bullet_scene.instantiate()
	if not bullet:
		return
	
	# Set bullet properties
	bullet.global_position = global_position
	bullet.speed = bullet_speed
	bullet.damage = bullet_damage
	
	# Set direction and rotation
	var direction = global_position.direction_to(closest_enemy.global_position)
	bullet.set_direction(direction)
	
	# Add bullet to scene
	if get_tree().current_scene:
		get_tree().current_scene.add_child(bullet)
	else:
		# Fallback: add to player's parent
		player.get_parent().add_child(bullet)
	
	# Play sound effect if available
	# play_shoot_sound()

func play_shoot_sound() -> void:
	# TODO: Add sound effect
	pass
