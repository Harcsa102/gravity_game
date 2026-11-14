
class_name LevelGoal
extends Area2D

signal reached(meteorite: Asteroid)

@export var goal_radius: float = 24.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true

	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = goal_radius
	$CollisionShape2D.shape = circle

	body_entered.connect(_on_body_entered)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	print("Goal detected: ", body.name)

	var asteroid: Asteroid = body as Asteroid

	if asteroid == null:
		print("Detected something, but it wasn't an Asteroid.")
		return

	if asteroid.flying and not asteroid.dead:
		print("Asteroid reached the goal!")
		reached.emit(asteroid)
		$"../Audio/Complete".play()

func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		goal_radius,
		Color(0.2, 1.0, 0.5, 0.12)
	)

	draw_arc(
		Vector2.ZERO,
		goal_radius,
		0.0,
		TAU,
		64,
		Color(0.2, 1.0, 0.5),
		2.0
	)
