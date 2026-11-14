
class_name Asteroid
extends CharacterBody2D

signal died

@export var maximum_speed: float = 500.0

var flying: bool = false
var dead: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1


func launch(initial_velocity: Vector2) -> void:
	if dead:
		return

	velocity = initial_velocity
	flying = true


func _physics_process(delta: float) -> void:
	if not flying or dead:
		return

	var acceleration: Vector2 = Vector2.ZERO
	var sources: Array[Node] = get_tree().get_nodes_in_group("gravity_planets")

	for node in sources:
		var planet: GravityPlanet = node as GravityPlanet

		if planet == null:
			continue

		var pull: Vector2 = planet.acceleration_at(global_position)
		acceleration += pull

	velocity += acceleration * delta
	velocity = velocity.limit_length(maximum_speed)

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)

	if collision != null:
		die()


func die() -> void:
	if dead:
		return

	dead = true
	flying = false
	velocity = Vector2.ZERO

	hide()
	collision_shape.set_deferred("disabled", true)

	died.emit()


func reset_to(start_position: Vector2) -> void:
	flying = false
	dead = false
	velocity = Vector2.ZERO
	global_position = start_position

	collision_shape.set_deferred("disabled", false)
	show()
