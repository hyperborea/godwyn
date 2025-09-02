class_name SawBlade
extends Area2D

@export var damage: int = 3
@export var orbit_radius: float = 00.0
@export var orbit_speed_deg: float = 260.0

var _player: Player
var _angle_deg: float = 0.0

func _ready() -> void:
	_player = get_parent() as Player
	if not _player:
		_player = get_node_or_null("/root/World/Player") as Player
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _player:
		return
	_angle_deg += orbit_speed_deg * delta
	var angle_rad: float = deg_to_rad(_angle_deg)
	var offset: Vector2 = Vector2(cos(angle_rad), sin(angle_rad)) * orbit_radius
	global_position = _player.global_position + offset

func _on_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy is Enemy:
		enemy.take_damage(damage)

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.take_damage(damage)
