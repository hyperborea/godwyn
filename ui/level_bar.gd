class_name LevelBar
extends Control

@export var kills_per_level: int = 10

var kills: int = 0

@onready var progress: ProgressBar = $ProgressBar
@onready var level_label: Label = $LevelLabel

signal level_up(new_level: int)
var _prev_level: int = 0

func _ready() -> void:
	progress.min_value = 0
	progress.max_value = kills_per_level
	progress.value = 0
	progress.show_percentage = true
	progress.add_theme_color_override("font_color", Color(1,1,1))
	_prev_level = _compute_level()
	_update_level_text()

func on_enemy_killed() -> void:
	kills += 1
	progress.value = kills % kills_per_level
	var lvl := _compute_level()
	if lvl > _prev_level:
		_prev_level = lvl
		level_up.emit(lvl)
	_update_level_text()

func _update_level_text() -> void:
	if level_label:
		var level := _compute_level()
		level_label.text = "Level: " + str(level)

func get_level() -> int:
	return _compute_level()

func _compute_level() -> int:
	return int(floor(float(kills) / float(kills_per_level)))
