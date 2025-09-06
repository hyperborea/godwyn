class_name Enemy
extends CharacterBody2D

enum State {
	SPAWNING,
	ALIVE,
	DEAD
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Player = %Player
@onready var hitbox: Area2D = $Hitbox

@export var move_speed: float = 150.0
@export var movement_threshold: float = 50.0
@export var max_health: int = 2
@export var health: int = 2

# Animation configuration to allow variants to override names
@export var anim_spawn: StringName = "smoke"
@export var anim_move: StringName = "walking"
@export var anim_die: StringName = "dying"
@export var anim_idle: StringName = "idle"
@export var anim_hurt: StringName = "" # Optional

# Behavior configuration
@export var always_chase_player: bool = false
 
# Optional spritesheet config for move animation (used by Dragon)
@export var use_move_spritesheet: bool = false
@export var move_sheet_texture: Texture2D
@export var move_sheet_columns: int = 8
@export var move_sheet_rows: int = 1
@export var move_sheet_frames: int = 8
@export var move_anim_fps: float = 12.0
signal enemy_died

var _overlapping_player := false
var current_state: State = State.SPAWNING


func _ready() -> void:
	# Fallback: if autoload player is not found, try to find it manually
	if not player:
		player = get_node("/root/World/Player")
	
	# Prepare spritesheet-based move animation if requested
	if use_move_spritesheet and move_sheet_texture:
		_build_move_animation_from_spritesheet()
	
	_spawn_with_smoke()
	hitbox.body_entered.connect(_on_hitbox_entered)
	hitbox.body_exited.connect(_on_hitbox_exited)


func _spawn_with_smoke() -> void:
	current_state = State.SPAWNING
	
	var frames := animated_sprite.sprite_frames
	if anim_spawn != StringName("") and frames and frames.has_animation(anim_spawn):
		animated_sprite.play(anim_spawn)
		var loops := frames.get_animation_loop(anim_spawn)
		if not loops:
			await animated_sprite.animation_finished
		else:
			await get_tree().create_timer(0.2).timeout
	else:
		await get_tree().create_timer(0.1).timeout
	
	current_state = State.ALIVE
	if frames and frames.has_animation(anim_move):
		animated_sprite.play(anim_move)
	elif frames and frames.has_animation(anim_idle):
		animated_sprite.play(anim_idle)


func _process(_delta: float) -> void:
	if current_state != State.ALIVE:
		return

	if _overlapping_player:
		player.take_damage(1)


func _physics_process(_delta: float) -> void:
	if current_state != State.ALIVE:
		return

	var direction = global_position.direction_to(player.global_position)
	if always_chase_player:
		velocity = direction * move_speed
		animated_sprite.flip_h = direction.x < 0
	else:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player > movement_threshold:
			velocity = direction * move_speed
			animated_sprite.flip_h = direction.x < 0
		else:
			velocity = Vector2.ZERO

	move_and_slide()


func _on_hitbox_entered(body: Node2D) -> void:
	if current_state == State.ALIVE and body is Player:
		_overlapping_player = true


func _on_hitbox_exited(body: Node2D) -> void:
	if current_state == State.ALIVE and body is Player:
		_overlapping_player = false


func take_damage(amount: int) -> void:
	if current_state != State.ALIVE:
		return

	health -= amount
	
	animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = Color.WHITE
	var frames := animated_sprite.sprite_frames
	if anim_hurt != StringName("") and frames and frames.has_animation(anim_hurt):
		animated_sprite.play(anim_hurt)
		await animated_sprite.animation_finished
		if current_state == State.ALIVE and frames.has_animation(anim_move):
			animated_sprite.play(anim_move)
	
	if health <= 0:
		_die()


func _die() -> void:
	current_state = State.DEAD
	_overlapping_player = false
	
	enemy_died.emit()
	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation(anim_die):
		animated_sprite.play(anim_die)
		var loops := frames.get_animation_loop(anim_die)
		if not loops:
			await animated_sprite.animation_finished
		else:
			await get_tree().create_timer(0.2).timeout
	queue_free()


func _build_move_animation_from_spritesheet() -> void:
	var frames := animated_sprite.sprite_frames
	if frames == null:
		return
	if anim_move == StringName(""):
		return
	if not frames.has_animation(anim_move):
		frames.add_animation(anim_move)
	# Clear existing frames for move anim
	frames.clear(anim_move)
	# Compute frame size
	var tex_size := move_sheet_texture.get_size()
	if move_sheet_columns <= 0 or move_sheet_rows <= 0:
		return
	var cell_w: int = int(tex_size.x) / max(1, move_sheet_columns)
	var cell_h: int = int(tex_size.y) / max(1, move_sheet_rows)
	var total: int = max(1, move_sheet_frames)
	var added := 0
	# Iterate rows/cols to build atlas frames
	for r in range(move_sheet_rows):
		for c in range(move_sheet_columns):
			if added >= total:
				break
			var region := Rect2(c * cell_w, r * cell_h, cell_w, cell_h)
			var atlas := AtlasTexture.new()
			atlas.atlas = move_sheet_texture
			atlas.region = region
			atlas.filter_clip = true
			frames.add_frame(anim_move, atlas)
			added += 1
	# Set animation speed and loop
	frames.set_animation_speed(anim_move, move_anim_fps)
	frames.set_animation_loop(anim_move, true)
