extends Node2D

@onready var meteorite: AsteroidProjectile = $Asteroids
@export var planet_scene: PackedScene

@export var planet_limit: int = 3

@export var click_radius: float = 14.0
@export var maximum_drag: float = 100.0
@export var power_multiplier: float = 4.0
@export var minimum_drag: float = 5.0

@onready var aim_line: Line2D = $AimLine
@onready var planets: Node2D = $Planets

@onready var goal: LevelGoal = $Goal
@onready var complete_label: Label = $HUD/LevelCompleteLabel

@export_file("*.tscn") var next_level: String = "level_1.tscn"

var level_complete: bool = false

var dragging: bool = false
var shot_taken: bool = false
var start_position: Vector2

var _placement_pending: bool = false
var _placement_position := Vector2.ZERO


func _ready() -> void:
	aim_line.clear_points()
	aim_line.hide()

	complete_label.text = "Level Complete!\nPress R to retry"
	complete_label.hide()

	if meteorite == null:
		push_error("Assign the Meteorite field on the Level root.")
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	start_position = meteorite.global_position

	meteorite.died.connect(reset_shot, CONNECT_DEFERRED)
	goal.reached.connect(_on_goal_reached)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	# Retry remains available after winning.
	if event.is_action_pressed("Retry"):
		reset_shot()
		return

	# Prevent aiming and placement after winning.
	if level_complete:
		return

	if event.is_action_pressed("Clear Planets"):
		clear_planets()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and not shot_taken and not dragging:
				_placement_position = get_global_mouse_position()
				_placement_pending = true

			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				try_start_drag()
			elif dragging:
				release_shot()


func _physics_process(_delta: float) -> void:
	# Collision queries run during the physics update.
	if not _placement_pending:
		return

	_placement_pending = false

	if not shot_taken and not dragging:
		try_place_planet(_placement_position)


func _process(_delta: float) -> void:
	if not dragging:
		return

	var pull := get_pull_vector()
	var origin := meteorite.global_position

	aim_line.clear_points()
	aim_line.add_point(aim_line.to_local(origin))
	aim_line.add_point(aim_line.to_local(origin + pull))


func try_start_drag() -> void:
	if shot_taken or meteorite.dead:
		return

	var distance := get_global_mouse_position().distance_to(
		meteorite.global_position
	)

	if distance <= click_radius:
		dragging = true
		aim_line.clear_points()
		aim_line.show()


func get_pull_vector() -> Vector2:
	var pull := (
		meteorite.global_position - get_global_mouse_position()
	)

	return pull.limit_length(maximum_drag)


func release_shot() -> void:
	var pull := get_pull_vector()

	dragging = false
	aim_line.hide()

	if pull.length() < minimum_drag:
		return

	shot_taken = true
	meteorite.launch(pull * power_multiplier)


func reset_shot() -> void:
	level_complete = false
	dragging = false
	shot_taken = false
	_placement_pending = false

	complete_label.hide()

	aim_line.clear_points()
	aim_line.hide()
	
	$Audio/Death.play()

	meteorite.reset_to(start_position)


func try_place_planet(world_position: Vector2) -> void:
	if planet_scene == null:
		push_error("Assign Planet.tscn to the Level's Planet Scene field.")
		return

	if planets.get_child_count() >= planet_limit:
		return

	var planet := planet_scene.instantiate() as GravityPlanet

	if planet == null:
		push_error("Planet.tscn must have planet.gd on its root.")
		return

	var clearance_radius := planet.body_radius + 4.0

	# Leave room around the meteorite's starting point.
	if world_position.distance_to(start_position) < (
		clearance_radius + 20.0
	):
		planet.free()
		return

	# Check spacing explicitly for existing planets.
	for child in planets.get_children():
		var existing := child as GravityPlanet

		if world_position.distance_to(existing.global_position) < (
			clearance_radius + existing.body_radius
		):
			planet.free()
			return

	# Reject placements overlapping walls.
	var shape := CircleShape2D.new()
	shape.radius = clearance_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, world_position)
	query.collision_mask = 1 | 4
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var hits := get_world_2d().direct_space_state.intersect_shape(
		query,
		1
	)

	if not hits.is_empty():
		planet.free()
		return

	planet.position = planets.to_local(world_position)
	planets.add_child(planet)


func clear_planets() -> void:
	if shot_taken or dragging:
		return

	_placement_pending = false

	for planet in planets.get_children():
		planets.remove_child(planet)
		planet.queue_free()

func _on_goal_reached(asteroid: AsteroidProjectile) -> void:
	if level_complete or asteroid != meteorite:
		return

	level_complete = true
	dragging = false
	shot_taken = true
	_placement_pending = false

	meteorite.flying = false
	meteorite.velocity = Vector2.ZERO

	aim_line.clear_points()
	aim_line.hide()

	complete_label.show()
	
	if not next_level.is_empty():
		await get_tree().create_timer(2.0).timeout

		if level_complete:
			get_tree().change_scene_to_file(next_level)
