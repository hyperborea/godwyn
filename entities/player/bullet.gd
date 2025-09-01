class_name Bullet
extends Area2D

@export var speed: float = 600.0
@export var damage: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.ZERO
var lifetime_timer: float = 0.0

func _ready() -> void:
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	# Move bullet
	position += direction * speed * delta
	
	# Update lifetime timer
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		queue_free()

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	# Rotate bullet sprite to face direction
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.take_damage(damage)
		queue_free()
	elif body is Player:
		# Don't damage player
		pass
	else:
		# Hit wall or other obstacle
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Enemy:
		parent.take_damage(damage)
		queue_free()
