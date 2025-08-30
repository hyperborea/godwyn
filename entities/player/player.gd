class_name Player
extends CharacterBody2D

signal health_changed(new_health: int)
signal player_died

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_box: Area2D = $AttackBox

@export var move_speed: float = 400.0
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.25
@export var invincible_duration: float = 0.5

@export var max_health: int = 10
@export var health: int = 10
@export var attack_damage: int = 1
@export var attack_duration: float = 0.5

var invincible_timer: float = 0.0

enum State {
	IDLE,
	RUNNING,
	DASHING,
	ATTACKING,
	DEAD
}

enum Direction {
	LEFT,
	RIGHT
}

var current_state: State = State.IDLE
var dash_timer: float = 0.0
var attack_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT
var blink_timer: float = 0.0
var is_blinking: bool = false
var direction: Direction = Direction.RIGHT


func _ready() -> void:
	change_state(State.IDLE)
	reset_blink_timer()
	self.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if invincible_timer > 0.0:
		invincible_timer -= delta


	if blink_timer > 0.0:
		blink_timer -= delta


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	handle_input()
	update_state(delta)
	handle_blinking()
	move_and_slide()


func handle_input() -> void:
	if Input.is_action_just_pressed("attack") and current_state != State.ATTACKING and current_state != State.DASHING:
		change_state(State.ATTACKING)
	elif Input.is_action_just_pressed("dash") and current_state != State.DASHING and current_state != State.ATTACKING:
		change_state(State.DASHING)


func update_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			handle_idle_state()
		State.RUNNING:
			handle_running_state()
		State.DASHING:
			handle_dashing_state(delta)
		State.ATTACKING:
			handle_attacking_state(delta)


func handle_idle_state() -> void:
	var input_vector = get_input_vector()
	
	if input_vector != Vector2.ZERO:
		last_direction = input_vector.normalized()
		change_state(State.RUNNING)
	else:
		velocity = Vector2.ZERO
		handle_blinking()


func handle_running_state() -> void:
	var input_vector = get_input_vector()
	
	if input_vector != Vector2.ZERO:
		last_direction = input_vector.normalized()
		velocity = last_direction * move_speed
	else:
		change_state(State.IDLE)


func handle_dashing_state(delta: float) -> void:
	dash_timer -= delta
	velocity = last_direction * dash_speed
	
	if dash_timer <= 0.0:
		change_state(State.IDLE)


func handle_attacking_state(delta: float) -> void:
	attack_timer -= delta
	velocity = Vector2.ZERO
	
	if attack_timer <= 0.0:
		change_state(State.IDLE)


func get_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		change_direction(Direction.RIGHT)
	elif Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		change_direction(Direction.LEFT)
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
		
	return input_vector


func change_direction(new_direction: Direction) -> void:
	if direction == new_direction:
		return

	direction = new_direction
	animated_sprite.flip_h = direction == Direction.LEFT
	position_attack_box()


func change_state(new_state: State) -> void:
	current_state = new_state
	
	match new_state:
		State.IDLE:
			animated_sprite.play("idle")
			reset_blink_timer()
		State.RUNNING:
			animated_sprite.play("running")
		State.DASHING:
			dash_timer = dash_duration
			invincible_timer = dash_duration + 0.5
			animated_sprite.play("sliding")
		State.ATTACKING:
			attack_timer = attack_duration
			animated_sprite.play("attacking")
			damage_enemies_in_front()


func handle_blinking() -> void:
	if not is_blinking and blink_timer <= 0.0:
		is_blinking = true
		animated_sprite.play("idle_blinking")

		await animated_sprite.animation_finished
	
		is_blinking = false
		if current_state == State.IDLE:
			animated_sprite.play("idle")
			reset_blink_timer()


func reset_blink_timer() -> void:
	blink_timer = randf_range(3.0, 8.0)


func take_damage(amount: int) -> void:
	if invincible_timer > 0.0 or current_state == State.DEAD:
		return

	invincible_timer = invincible_duration
	
	health -= amount
	health_changed.emit(health)

	if health <= 0:
		player_died.emit()
		return

	animated_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	await get_tree().create_timer(0.2).timeout
	animated_sprite.modulate = Color.WHITE


func position_attack_box() -> void:
	var collision_shape = attack_box.get_child(0) as CollisionShape2D
	var base_x = abs(collision_shape.position.x)
	
	if direction == Direction.LEFT:
		collision_shape.position.x = - base_x
	else:
		collision_shape.position.x = base_x


func damage_enemies_in_front() -> void:
	position_attack_box()
	
	await get_tree().process_frame
	
	var bodies_in_attack_box = attack_box.get_overlapping_bodies()
	
	for body in bodies_in_attack_box:
		if body is Enemy:
			body.take_damage(attack_damage)


func _on_player_died() -> void:
	change_state(State.DEAD)
	animated_sprite.play("dying")
	velocity = Vector2.ZERO
