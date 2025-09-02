class_name ShopMenu
extends Control

const ALL_ITEMS := [
	"ultimate_cooldown",
	"auto_weapon_velocity",
	"auto_weapon_damage",
	"speed",
	"health",
	"saw_blade",
]

var current_items: Array = []

@onready var buttons: Array[Button] = [
	$Panel/VBox/Item1,
	$Panel/VBox/Item2,
	$Panel/VBox/Item3,
	$Panel/VBox/Item4,
]
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var reroll_button: Button = $Panel/VBox/RerollButton

const BASE_COST := 10
const COST_PER_WAVE := 3
var _reroll_index: int = 0

func _ready() -> void:
	randomize_items()
	_connect_buttons()

func open_shop() -> void:
	randomize_items()
	for b in buttons:
		b.disabled = false
		b.visible = true
	visible = true
	_reroll_index = 0
	_update_reroll_button_text()
	_update_affordability_tints()

func _current_cost() -> int:
	var wave: int = 1
	var world = get_tree().current_scene
	if world and world.has_method("get_wave"):
		wave = world.get_wave()
	return BASE_COST + COST_PER_WAVE * max(0, wave - 1)

func randomize_items() -> void:
	current_items = ALL_ITEMS.duplicate()
	current_items.shuffle()
	current_items = current_items.slice(0, 4)
	var cost: int = _current_cost()
	for i in range(buttons.size()):
		var key: String = str(current_items[i])
		buttons[i].text = _item_to_label(key) + "\n(" + key + ")\nCost: " + str(cost)

func _connect_buttons() -> void:
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_item_pressed.bind(i))
	reroll_button.pressed.connect(_on_reroll_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_item_pressed(idx: int) -> void:
	if idx < 0 or idx >= current_items.size():
		return
	var world = get_tree().current_scene
	if not world or not world.has_method("spend_money"):
		return
	var cost: int = _current_cost()
	if not world.spend_money(cost):
		return
	var effect_key: String = str(current_items[idx])
	_apply_effect(effect_key)
	# Hide/disable this item for this wave
	buttons[idx].disabled = true
	buttons[idx].visible = false
	_update_affordability_tints()

func _on_reroll_pressed() -> void:
	var world = get_tree().current_scene
	if not world or not world.has_method("spend_money"):
		return
	var cost: int = _current_reroll_cost()
	if not world.spend_money(cost):
		return
	_reroll_index += 1
	randomize_items()
	for b in buttons:
		b.disabled = false
		b.visible = true
	_update_reroll_button_text()
	_update_affordability_tints()

func _on_close_pressed() -> void:
	_hide_and_next_wave()

func _hide_and_next_wave() -> void:
	visible = false
	var world = get_tree().current_scene
	if world and world.has_method("start_next_wave"):
		world.start_next_wave()

func _apply_effect(effect_key: String) -> void:
	var world = get_tree().current_scene
	if world and world.has_method("apply_shop_effect"):
		world.apply_shop_effect(effect_key)

func _update_affordability_tints() -> void:
	var world = get_tree().current_scene
	var cost: int = _current_cost()
	var can_buy: bool = true
	if world and world.has_method("can_afford"):
		can_buy = world.can_afford(cost)
	for b in buttons:
		if not b.visible:
			continue
		if can_buy:
			b.modulate = Color(1,1,1,1)
		else:
			b.modulate = Color(1,0.8,0.8,1)
	# Reroll tint
	var reroll_can: bool = true
	if world and world.has_method("can_afford"):
		reroll_can = world.can_afford(_current_reroll_cost())
	if reroll_can:
		reroll_button.modulate = Color(1,1,1,1)
	else:
		reroll_button.modulate = Color(1,0.8,0.8,1)

# Reroll pricing: 2,5,7,12,17,23, then +10 each (33,43,53,...) with +10% per wave
func _base_reroll_cost_for_index(idx: int) -> int:
	match idx:
		0:
			return 2
		1:
			return 5
		2:
			return 7
		3:
			return 12
		4:
			return 17
		5:
			return 23
		_:
			return 23 + 10 * (idx - 5)

func _current_reroll_cost() -> int:
	var idx: int = max(0, _reroll_index)
	var base_cost: int = _base_reroll_cost_for_index(idx)
	# Apply +10% per wave multiplier
	var wave: int = 1
	var world = get_tree().current_scene
	if world and world.has_method("get_wave"):
		wave = world.get_wave()
	var multiplier: float = pow(1.1, float(max(0, wave - 1)))
	var final_cost: int = int(round(float(base_cost) * multiplier))
	return max(1, final_cost)

func _update_reroll_button_text() -> void:
	reroll_button.text = "Reroll (" + str(_current_reroll_cost()) + ")"

func _item_to_label(key: String) -> String:
	match key:
		"ultimate_cooldown":
			return "Ultimate cooldown: -5s"
		"auto_weapon_velocity":
			return "Auto weapon velocity: -0.5s fire rate"
		"auto_weapon_damage":
			return "Auto weapon damage: +1"
		"speed":
			return "Speed: +100"
		"health":
			return "Health: +5"
		"saw_blade":
			return "Saw blade: orbiting blade (+3 dmg)"
		_:
			return key
