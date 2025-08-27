class_name HealthBar
extends Control

@export var player: Player

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label


func _ready() -> void:
	progress_bar.max_value = player.max_health
	progress_bar.value = player.health
	label.text = _format_string()

	player.health_changed.connect(_on_health_changed)


func _on_health_changed(new_health: int) -> void:
	progress_bar.value = new_health
	label.text = _format_string()


func _format_string() -> String:
	return str(player.health) + " / " + str(player.max_health)
