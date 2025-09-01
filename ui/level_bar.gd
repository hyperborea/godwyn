class_name LevelBar
extends Control

@export var kills_per_level: int = 10

var kills: int = 0

@onready var progress: ProgressBar = $ProgressBar
@onready var level_label: Label = $LevelLabel

func _ready() -> void:
	progress.min_value = 0
	progress.max_value = kills_per_level
	progress.value = 0
	progress.show_percentage = true
	progress.add_theme_color_override("font_color", Color(1,1,1))
	_update_level_text()

func on_enemy_killed() -> void:
	kills += 1
	progress.value = kills % kills_per_level
	_update_level_text()

func _update_level_text() -> void:
	if level_label:
		var level := int(floor(float(kills) / float(kills_per_level)))
		level_label.text = "Level: " + str(level)

func get_level() -> int:
	return int(floor(float(kills) / float(kills_per_level)))
