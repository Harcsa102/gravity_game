class_name AsteroidProjectile
extends CharacterBody2D

signal crashed(reason: String)

@export var maximum_flight_time: float = 12.0
@export var maximum_speed: float = 350.0
@export var trail_point_limit: int = 160

var flying: bool = false

var _flight_time: float = 0.0
var _gravity_sources: Array[GravityPlanet] = []
var _flight_bounds: Rect2

@onready var trail: Line2D = get_node_or_null("Trail") as Line2D


func _ready() -> void:
	# Layer 2: asteroid. Detect layer 1: solid objects.
	collision_layer = 2
	collision_mask = 1

	if trail != null:
		# Trail points use world coordinates.
		# Moving the asteroid must not move previous points.
		trail.top_level = true
		trail.global_transform = Transform2D.IDENTITY
		trail.clear_points()


func launch(
	start: Vector2,
	initial_velocity: Vector2,
	sources: Array[GravityPlanet],
	bounds: Rect2
) -> void:
	global_position = start
	velocity = initial_velocity
	_gravity_sources = sources
	_flight_bounds = bounds
	_flight_time = 0.0
	flying = true

	if trail != null:
		trail.clear_points()
		trail.add_point(global_position)


func stop() -> void:
	flying = false
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not flying:
		return

	var acceleration := Vector2.ZERO

	for planet in _gravity_sources:
		if is_instance_valid(planet):
			acceleration += planet.acceleration_at(global_position)

	velocity += acceleration * delta
	velocity = velocity.limit_length(maximum_speed)

	var collision := move_and_collide(velocity * delta)

	if trail != null:
		trail.add_point(global_position)

		if trail.get_point_count() > trail_point_limit:
			trail.remove_point(0)

	if collision != null:
		_fail("The asteroid hit something.")
		return

	_flight_time += delta

	if _flight_time >= maximum_flight_time:
		_fail("Flight time ran out.")
		return

	if not _flight_bounds.has_point(global_position):
		_fail("The asteroid left the level.")


func _fail(reason: String) -> void:
	stop()
	crashed.emit(reason)
