class_name GameTimer
extends Control

@export var start_seconds: int = 30

var time_left: float = 0.0
var finished_emitted: bool = false

@onready var label: Label = $Label
@onready var wave_label: Label = $WaveLabel

signal timer_finished

func _ready() -> void:
	time_left = float(max(0, start_seconds))
	finished_emitted = false
	_update_label()
	_update_wave_label()

func _process(delta: float) -> void:
	if time_left <= 0.0:
		if not finished_emitted:
			finished_emitted = true
			_show_wave_over()
			timer_finished.emit()
		return
	
	time_left = max(0.0, time_left - delta)
	_update_label()

func _update_label() -> void:
	if label:
		var seconds_left := int(ceil(time_left))
		label.text = str(seconds_left)

func _show_wave_over() -> void:
	if label:
		label.text = "Wave Over"

# Wave label support
var _current_wave: int = 1

func _update_wave_label() -> void:
	if wave_label:
		wave_label.text = "Wave " + str(_current_wave)

func get_wave() -> int:
	return _current_wave

func set_wave(wave: int) -> void:
	_current_wave = max(1, wave)
	_update_wave_label()
