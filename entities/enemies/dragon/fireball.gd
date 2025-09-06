class_name DragonFireball
extends Area2D

@export var speed: float = 400.0
@export var damage: int = 1
@export var lifetime: float = 4.0

var _direction: Vector2 = Vector2.ZERO
var _life: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_direction(dir: Vector2) -> void:
	_direction = dir.normalized()
	rotation = _direction.angle()

func _process(delta: float) -> void:
	position += _direction * speed * delta
	_life += delta
	if _life >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player:
		parent.take_damage(damage)
		queue_free()

