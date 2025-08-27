class_name Enemy
extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Player = %Player
@onready var hitbox: Area2D = $Hitbox

@export var move_speed: float = 150.0
@export var movement_threshold: float = 50.0
@export var max_health: int = 2
@export var health: int = 2

var _overlapping_player := false
var is_dead := false


func _ready() -> void:
	animated_sprite.play("walking")
	hitbox.body_entered.connect(_on_hitbox_entered)
	hitbox.body_exited.connect(_on_hitbox_exited)


func _process(_delta: float) -> void:
	if is_dead:
		return

	if _overlapping_player:
		player.take_damage(1)


func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > movement_threshold:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
		animated_sprite.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _on_hitbox_entered(body: Node2D) -> void:
	if body is Player:
		_overlapping_player = true


func _on_hitbox_exited(body: Node2D) -> void:
	if body is Player:
		_overlapping_player = false


func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	
	animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = Color.WHITE
	
	if health <= 0:
		is_dead = true
		animated_sprite.play("dying")
		await animated_sprite.animation_finished
		animated_sprite.play("smoke")
		await animated_sprite.animation_finished
		queue_free()
