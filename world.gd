extends Node2D

@onready var spawner = %EnemySpawner
@onready var game_timer = %GameTimer
@onready var level_bar = %LevelBar
@onready var player = %Player
@onready var attack_timer = %AttackTimer
@onready var next_wave_button = %NextWaveButton
@onready var shop_menu = %ShopMenu
@onready var money_label: Label = %MoneyLabel
var money: int = 0
@onready var health_bar: HealthBar = %HealthBar

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
	if level_bar:
		level_bar.level_up.connect(_on_level_up)
	if spawner:
		spawner.enemy_killed.connect(_on_enemy_killed_reward)
		spawner.enemy_killed_at.connect(_on_enemy_killed_at)
	# Provide player access to attack cooldown timer if needed
	if player and attack_timer:
		player.set_meta("attack_timer_path", attack_timer.get_path())
	# Wire next wave button
	if next_wave_button:
		next_wave_button.pressed.connect(_on_next_wave_pressed)

func _on_enemy_killed_reward() -> void:
	# retained for other rewards (not used for money now)
	pass

func _on_enemy_killed_at(pos: Vector2) -> void:
	var gain := randi_range(0, 3)
	if gain <= 0:
		return
	var pickup_scene := load("res://entities/money_pickup.tscn") as PackedScene
	if pickup_scene:
		for i in range(gain):
			var p := pickup_scene.instantiate()
			if p:
				p.amount = 1
				var ang := randf() * TAU
				var dist := randf_range(5.0, 25.0)
				var off := Vector2(cos(ang), sin(ang)) * dist
				p.global_position = pos + off
				add_child(p)

func add_money(amount: int) -> void:
	money += amount
	if money_label:
		money_label.text = "Money: " + str(money)

func can_afford(cost: int) -> bool:
	return money >= cost

func spend_money(cost: int) -> bool:
	if money < cost:
		return false
	money -= cost
	if money_label:
		money_label.text = "Money: " + str(money)
	return true

func _on_level_up(_new_level: int) -> void:
	# +1 max health on each level up during the wave
	if player:
		player.max_health += 1
		# Also grant +1 current health on level
		player.health = min(player.max_health, player.health + 1)
		# Grant exactly one auto weapon per level up
		var weapon_scene := load("res://entities/player/auto_weapon.tscn") as PackedScene
		if weapon_scene:
			var w := weapon_scene.instantiate()
			if w:
				player.add_child(w)
				_redistribute_auto_weapons()
		# Keep current health unchanged; just refresh UI
		if health_bar:
			health_bar.refresh()

func _on_timer_finished() -> void:
	if spawner:
		spawner.stop_spawning()
		spawner.clear_all_enemies()
	# Show next wave button
	if next_wave_button:
		next_wave_button.visible = true
	# Show shop menu
	if shop_menu:
		# Prefer opening via method to refresh items
		if shop_menu.has_method("open_shop"):
			shop_menu.open_shop()
		else:
			shop_menu.visible = true
		# Refill player health at wave end
		if player:
			player.health = player.max_health

func _on_next_wave_pressed() -> void:
	# Reset game timer and resume spawns
	var game_timer_node = game_timer
	if game_timer_node:
		game_timer_node.finished_emitted = false
		# Increase wave timer by +5 per wave
		game_timer_node.start_seconds += 5
		game_timer_node.time_left = float(max(0, game_timer_node.start_seconds))
		# Increment wave number and update label
		game_timer_node.set_wave(game_timer_node.get_wave() + 1)
	# Hide the button
	if next_wave_button:
		next_wave_button.visible = false
	# Reactivate spawner
	if spawner:
		# Increase enemy health bonus by 1 each wave
		spawner.wave_bonus_health += 1
		spawner.is_active = true
		spawner._start_spawn_timer()
		spawner.spawn_initial_enemies()

# Called by shop_menu to proceed
func start_next_wave() -> void:
	_on_next_wave_pressed()

# Apply shop choices
func apply_shop_effect(effect_key: String) -> void:
	match effect_key:
		"ultimate_cooldown":
			if attack_timer:
				attack_timer.start_seconds = max(1, attack_timer.start_seconds - 5)
		"auto_weapon_velocity":
			# Reduce fire_rate by 0.5 on all auto weapons under player
			if player:
				for w in player.get_children():
					if w is AutoWeapon:
						w.fire_rate = max(0.1, w.fire_rate - 0.5)
		"auto_weapon_damage":
			if player:
				for w in player.get_children():
					if w is AutoWeapon:
						w.bullet_damage += 1
		"speed":
			if player:
				player.move_speed += 100.0
		"health":
			if player:
				player.max_health += 5
				player.health += 5

func get_wave() -> int:
	if game_timer and game_timer.has_method("get_wave"):
		return game_timer.get_wave()
	return 1

func _redistribute_auto_weapons() -> void:
	if not player:
		return
	var weapons: Array = []
	for c in player.get_children():
		if c is AutoWeapon:
			weapons.append(c)
	var n := weapons.size()
	if n == 0:
		return
	for i in range(n):
		weapons[i].orbit_angle = float(i) * (360.0 / float(n))
