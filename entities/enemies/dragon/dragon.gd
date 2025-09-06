class_name Dragon
extends Enemy

@export var attack_interval_min: float = 2.0
@export var attack_interval_max: float = 4.0
@export var charge_speed: float = 600.0
@export var charge_duration: float = 0.6
@export var simple_attack_duration: float = 0.8
@export var dash_speed: float = 500.0
@export var dash_distance: float = 700.0
@export var dashes_per_attack: int = 3

var _attack_timer: float = 0.0
var _is_attacking: bool = false
var _current_attack: StringName = StringName("")
var _attack_time_left: float = 0.0
var _dash_count: int = 0
var _dash_remaining: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _awakened: bool = false

# Random wandering movement when not attacking
@export var wander_speed: float = 150.0
@export var wander_interval_min: float = 1.0
@export var wander_interval_max: float = 2.5
@export var wander_idle_chance: float = 0.0  # No idling; always moving while alive
var _wander_dir: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0

# Spritesheet slicing for non-walk animations
@export var flight_columns: int = 12
@export var flight_rows: int = 1
@export var flight_frames: int = 12
@export var flight_fps: float = 12.0

@export var attack1_columns: int = 12
@export var attack1_rows: int = 1
@export var attack1_frames: int = 12
@export var attack1_fps: float = 12.0

@export var attack2_columns: int = 12
@export var attack2_rows: int = 1
@export var attack2_frames: int = 12
@export var attack2_fps: float = 12.0

@export var special_columns: int = 12
@export var special_rows: int = 1
@export var special_frames: int = 12
@export var special_fps: float = 12.0

@export var dead_columns: int = 12
@export var dead_rows: int = 1
@export var dead_frames: int = 12
@export var dead_fps: float = 12.0

@export var hurt_columns: int = 12
@export var hurt_rows: int = 1
@export var hurt_frames: int = 12
@export var hurt_fps: float = 12.0

@export var rise_columns: int = 12
@export var rise_rows: int = 1
@export var rise_frames: int = 12
@export var rise_fps: float = 12.0

@export var landing_columns: int = 12
@export var landing_rows: int = 1
@export var landing_frames: int = 12
@export var landing_fps: float = 12.0

# Global spritesheet margins/spacing (applied to non-walk animations)
@export var sheet_margin_x: int = 0
@export var sheet_margin_y: int = 0
@export var sheet_spacing_x: int = 0
@export var sheet_spacing_y: int = 0

# Fireball attack
@export var fireball_scene: PackedScene
@export var fireball_speed: float = 500.0
@export var fireball_count: int = 1
@export var fireball_spread_deg: float = 0.0
@export var fireball_burst_min: int = 3
@export var fireball_burst_max: int = 5
@export var fireball_burst_interval: float = 0.35
var _fireball_burst_left: int = 0
var _fireball_burst_timer: float = 0.0
var _is_fireballing: bool = false

func _ready() -> void:
	# Do not follow by default; attacks control movement
	always_chase_player = false
	# Ensure dragon animation names map to sprites in the frames
	# Only fly around randomly (no attacks)
	anim_spawn = ""
	anim_move = "flight"
	anim_die = "dead"
	anim_idle = "flight"
	anim_hurt = ""  # Avoid hurt override conflicting with first-hit sequence

	# Enforce nearest filtering to reduce bleed
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Join enemies group for detection
	add_to_group("enemies")
	
	# Initialize next attack timer
	_attack_timer = randf_range(attack_interval_min, attack_interval_max)
	# Initialize wandering
	_pick_new_wander()
	
	# Slice spritesheets for non-walk animations (walk handled via Enemy config)
	_slice_if_needed("flight", flight_columns, flight_rows, flight_frames, flight_fps)
	_slice_if_needed("attack1", attack1_columns, attack1_rows, attack1_frames, attack1_fps)
	_slice_if_needed("attack2", attack2_columns, attack2_rows, attack2_frames, attack2_fps)
	_slice_if_needed("special", special_columns, special_rows, special_frames, special_fps)
	_slice_if_needed("dead", dead_columns, dead_rows, dead_frames, dead_fps)
	_slice_if_needed("hurt", hurt_columns, hurt_rows, hurt_frames, hurt_fps)
	_slice_if_needed("rise", rise_columns, rise_rows, rise_frames, rise_fps)
	_slice_if_needed("landing", landing_columns, landing_rows, landing_frames, landing_fps)

	# Call parent _ready (spawning animation & hitbox connections)
	super()

	# Ensure we are visibly flying immediately
	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation(anim_move):
		animated_sprite.play(anim_move)


func _process(_delta: float) -> void:
	if current_state != State.ALIVE:
		return
	# Attack timer for triple dash
	if not _is_attacking:
		_attack_timer -= _delta
		if _attack_timer <= 0.0:
			_attack_timer = randf_range(attack_interval_min, attack_interval_max)
			_start_random_attack()

	# Handle one-at-a-time fireball during burst
	if _is_fireballing:
		_fireball_burst_timer -= _delta
		if _fireball_burst_timer <= 0.0:
			_fireball_burst_timer = fireball_burst_interval
			_fireball_once()

func _physics_process(delta: float) -> void:
	if current_state != State.ALIVE:
		return
	
	if _is_attacking:
		# Triple dash movement
		var move_amount: float = dash_speed * delta
		velocity = _dash_dir * dash_speed
		_dash_remaining -= move_amount
		animated_sprite.flip_h = _dash_dir.x < 0.0
		if _dash_remaining <= 0.0:
			if _dash_count > 1:
				_dash_count -= 1
				_dash_dir = global_position.direction_to(player.global_position).normalized()
				_dash_remaining = dash_distance
				var frames_a := animated_sprite.sprite_frames
				if frames_a and frames_a.has_animation("special"):
					animated_sprite.play("special")
			else:
				_end_attack()
	else:
		# Wander movement while waiting for next attack (disabled during fireball burst)
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_pick_new_wander()
		if _is_fireballing:
			velocity = Vector2.ZERO
		else:
			velocity = _wander_dir * wander_speed
		if _wander_dir.x != 0.0:
			animated_sprite.flip_h = _wander_dir.x < 0.0
		# Ensure flight animation stays active
		if not _is_fireballing and animated_sprite.animation != anim_move:
			animated_sprite.play(anim_move)

	move_and_slide()


func _start_random_attack() -> void:
	# 80%: fireball burst (attack2), 20%: triple dash (special)
	if randf() < 0.8:
		_start_fireball_burst()
	else:
		_is_attacking = true
		_current_attack = StringName("triple_dash")
		_dash_count = dashes_per_attack
		_dash_remaining = dash_distance
		_dash_dir = global_position.direction_to(player.global_position).normalized()
		var frames := animated_sprite.sprite_frames
		if frames and frames.has_animation("special"):
			animated_sprite.play("special")


func _start_fireball_burst() -> void:
	_is_fireballing = true
	_fireball_burst_left = randi_range(fireball_burst_min, fireball_burst_max)
	_fireball_burst_timer = 0.0
	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation("attack2"):
		animated_sprite.play("attack2")
	elif frames and frames.has_animation("special"):
		animated_sprite.play("special")


func _fireball_once() -> void:
	if not _is_fireballing:
		return
	if _fireball_burst_left <= 0:
		_is_fireballing = false
		return
	if not fireball_scene:
		_is_fireballing = false
		return
	var dir: Vector2 = global_position.direction_to(player.global_position).normalized()
	var world := get_tree().current_scene
	var fb := fireball_scene.instantiate()
	if fb:
		fb.global_position = global_position
		if fb.has_method("set_direction"):
			fb.set_direction(dir)
		if "speed" in fb:
			fb.speed = fireball_speed
		if world:
			world.add_child(fb)
	_fireball_burst_left -= 1


func _start_attack(_attack_name: StringName) -> void:
	_start_random_attack()


func _end_attack() -> void:
	_is_attacking = false
	_current_attack = StringName("")
	_attack_time_left = 0.0
	velocity = Vector2.ZERO
	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation(anim_move):
		animated_sprite.play(anim_move)


func _fireball_attack() -> void:
	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation("attack1"):
		animated_sprite.play("attack1")
	elif frames and frames.has_animation("special"):
		animated_sprite.play("special")
	if not fireball_scene:
		return
	var base_dir: Vector2 = global_position.direction_to(player.global_position).normalized()
	var half_spread: float = fireball_spread_deg * 0.5
	var world := get_tree().current_scene
	for i in range(fireball_count):
		var fb := fireball_scene.instantiate()
		if fb:
			fb.global_position = global_position
			var angle_offset_deg: float = randf_range(-half_spread, half_spread)
			var dir := base_dir.rotated(deg_to_rad(angle_offset_deg))
			if fb.has_method("set_direction"):
				fb.set_direction(dir)
			if "speed" in fb:
				fb.speed = fireball_speed
			if world:
				world.add_child(fb)


func take_damage(amount: int) -> void:
	if current_state != State.ALIVE:
		return
	
	# First-time awaken sequence: play rise once, then flight
	if not _awakened:
		_awakened = true
		var frames := animated_sprite.sprite_frames
		if frames and frames.has_animation("rise"):
			animated_sprite.play("rise")
			var loops := frames.get_animation_loop("rise")
			if not loops:
				await animated_sprite.animation_finished
			else:
				await get_tree().create_timer(0.3).timeout
		# From now on, the dragon should be flying
		anim_move = "flight"
		if frames and frames.has_animation(anim_move):
			animated_sprite.play(anim_move)
	
	# Damage flash & reduce HP (replicating parent logic, without hurt anim)
	health -= amount
	animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = Color.WHITE
	
	if health <= 0:
		_die()


func _slice_if_needed(anim_name: StringName, columns: int, rows: int, frames_count: int, fps: float) -> void:
	var frames: SpriteFrames = animated_sprite.sprite_frames
	if frames == null:
		return
	if not frames.has_animation(anim_name):
		return
	var count: int = frames.get_frame_count(anim_name)
	if count != 1:
		return
	var base_tex: Texture2D = frames.get_frame_texture(anim_name, 0)
	if base_tex == null:
		return
	# Build atlas frames
	frames.clear(anim_name)
	var tex_size: Vector2 = base_tex.get_size()
	if columns <= 0 or rows <= 0:
		return
	# Compute cell size accounting for margins and spacing
	var avail_w: int = int(tex_size.x) - (sheet_margin_x * 2) - (sheet_spacing_x * max(0, columns - 1))
	var avail_h: int = int(tex_size.y) - (sheet_margin_y * 2) - (sheet_spacing_y * max(0, rows - 1))
	if avail_w <= 0 or avail_h <= 0:
		return
	var cell_w: int = avail_w / max(1, columns)
	var cell_h: int = avail_h / max(1, rows)
	var total: int = max(1, frames_count)
	var added: int = 0
	for r in range(rows):
		for c in range(columns):
			if added >= total:
				break
			var rx: int = sheet_margin_x + c * (cell_w + sheet_spacing_x)
			var ry: int = sheet_margin_y + r * (cell_h + sheet_spacing_y)
			var region: Rect2 = Rect2(rx, ry, cell_w, cell_h)
			var atlas := AtlasTexture.new()
			atlas.atlas = base_tex
			atlas.region = region
			atlas.filter_clip = true
			frames.add_frame(anim_name, atlas)
			added += 1
	frames.set_animation_speed(anim_name, fps)
	# Loop flight/landing; leave others as currently defined
	if anim_name == StringName("flight") or anim_name == StringName("landing"):
		frames.set_animation_loop(anim_name, true)


func _pick_new_wander() -> void:
	# Choose a new random direction or idle
	var will_idle: bool = randf() < clamp(wander_idle_chance, 0.0, 1.0)
	if will_idle:
		_wander_dir = Vector2.ZERO
	else:
		var ang: float = randf() * TAU
		_wander_dir = Vector2(cos(ang), sin(ang)).normalized()
	_wander_timer = randf_range(wander_interval_min, wander_interval_max)
	# Ensure we are in move animation while wandering
	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation(anim_move):
		animated_sprite.play(anim_move)
