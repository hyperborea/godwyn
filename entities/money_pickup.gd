class_name MoneyPickup
extends Area2D

@export var amount: int = 1
@export var lifetime_seconds: float = 20.0
@export var magnet_radius: float = 300.0
@export var magnet_speed: float = 900.0
@export var collect_distance: float = 12.0

var _age: float = 0.0
var _player: Player

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_player = get_node_or_null("/root/World/Player") as Player

func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime_seconds:
		queue_free()

	if _player:
		var to_player := _player.global_position - global_position
		var dist := to_player.length()
		if dist <= magnet_radius:
			var dir := to_player.normalized()
			# Speed scales up as it gets closer
			var speed: float = magnet_speed * (1.1 - clamp(dist / magnet_radius, 0.0, 1.0))
			global_position += dir * speed * delta
			if dist <= collect_distance:
				_collect()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_collect()

func _collect() -> void:
	var world = get_tree().current_scene
	if world and world.has_method("add_money"):
		world.add_money(amount)
	queue_free()
