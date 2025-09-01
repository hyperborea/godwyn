class_name AttackTimer
extends Control

@export var start_seconds: int = 15

var time_left: float = 0.0
var finished_emitted: bool = false

@onready var label: Label = $Label

signal attack_timer_finished

func _ready() -> void:
	# Start ready at wave start
	time_left = 0.0
	finished_emitted = false
	_update_label()

func _process(delta: float) -> void:
	if time_left <= 0.0:
		if not finished_emitted:
			finished_emitted = true
			attack_timer_finished.emit()
		if label:
			label.text = "Ready"
		return
	
	time_left = max(0.0, time_left - delta)
	_update_label()

func _update_label() -> void:
	if label:
		if time_left <= 0.0:
			label.text = "Ready"
		else:
			var seconds_left := int(ceil(time_left))
			label.text = str(seconds_left)

# Public API
func start(duration_seconds: int = -1) -> void:
	if duration_seconds <= 0:
		duration_seconds = start_seconds
	time_left = float(duration_seconds)
	finished_emitted = false
	_update_label()

func reset() -> void:
	start(start_seconds)

func is_ready() -> bool:
	return time_left <= 0.0
