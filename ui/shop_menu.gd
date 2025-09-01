class_name ShopMenu
extends Control

const ALL_ITEMS := [
	"ultimate_cooldown",
	"auto_weapon_velocity",
	"auto_weapon_damage",
	"speed",
	"health",
]

var current_items: Array = []

@onready var buttons: Array[Button] = [
	$Panel/VBox/Item1,
	$Panel/VBox/Item2,
	$Panel/VBox/Item3,
	$Panel/VBox/Item4,
]
@onready var close_button: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	randomize_items()
	_connect_buttons()

func randomize_items() -> void:
	current_items = ALL_ITEMS.duplicate()
	current_items.shuffle()
	current_items = current_items.slice(0, 4)
	for i in range(buttons.size()):
		var key: String = str(current_items[i])
		buttons[i].text = _item_to_label(key) + "\n(" + key + ")"

func _connect_buttons() -> void:
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_item_pressed.bind(i))
	close_button.pressed.connect(_on_close_pressed)

func _on_item_pressed(idx: int) -> void:
	if idx < 0 or idx >= current_items.size():
		return
	var effect_key: String = str(current_items[idx])
	_apply_effect(effect_key)
	_hide_and_next_wave()

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
		_:
			return key
