extends StaticBody2D

@export var gravity_strength: float = 100000.0
@export var influence_radius: float = 180.0
@export var softening: float = 20.0
@export var surface_radius: float = 12.0

@onready var field_visual: GravityFieldVisual = $FieldVisual


func _ready() -> void:
	# Layer 1: solid objects.
	collision_layer = 1
	collision_mask = 0

	# Give each planet its own collision shape.
	var circle := CircleShape2D.new()
	circle.radius = surface_radius
	$CollisionShape2D.shape = circle

	field_visual.radius = influence_radius
	field_visual.queue_redraw()


func acceleration_at(point: Vector2) -> Vector2:
	var offset := global_position - point
	var distance_squared := offset.length_squared()

	if distance_squared < 0.001:
		return Vector2.ZERO

	if distance_squared > influence_radius * influence_radius:
		return Vector2.ZERO

	var strength := gravity_strength / (
		distance_squared + softening * softening
	)

	return offset.normalized() * strength
