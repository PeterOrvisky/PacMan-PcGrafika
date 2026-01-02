extends CharacterBody2D
class_name Player

signal player_died(life: int)

var next_movement_direction = Vector2.ZERO
var movement_direction = Vector2.ZERO
var shape_query = PhysicsShapeQueryParameters2D.new()
var is_invulnerable = false
var is_dying = false

@export var speed = 300
@export var start_position: Node2D
@export var pacman_death_sound_player: AudioStreamPlayer2D
@export var pellets_manager: PelletsManager
@export var lifes: int = 2
@export var ui: UI  # Prepojenie na uzol UI

@onready var direction_pointer = $DirectionPointer
@onready var collision_shape_2d = $CollisionShape2D
@onready var animation_player = $AnimationPlayer

func _ready():
	# Zabezpečíme, že uzol UI je správne prepojený
	if ui == null:
		ui = get_parent().get_node("UI")  # Zmeňte cestu podľa štruktúry vašej scény
	if ui != null:
		# Namiesto TYPE_FUNCTION použijeme has_method()
		if ui.has_method("set_lifes"):
			ui.set_lifes(lifes)  # Aktualizácia životov v UI
		else:
			push_error("Method set_lifes() does not exist on UI.")
	else:
		push_error("UI node is not set. Please check the scene.")
	reset_player()

func reset_player():
	animation_player.play("default")
	if start_position != null:
		position = start_position.position
	else:
		push_error("Start position is not set!")
	set_physics_process(true)
	set_collision_layer_value(1, true)
	next_movement_direction = Vector2.ZERO
	movement_direction = Vector2.ZERO
	is_invulnerable = true
	is_dying = false
	await get_tree().create_timer(2.0).timeout  # 2 sekundy ochrany
	is_invulnerable = false

func _physics_process(delta):
	get_input()
	if movement_direction == Vector2.ZERO:
		movement_direction = next_movement_direction
	if can_move_in_direction(next_movement_direction, delta):
		movement_direction = next_movement_direction

	velocity = movement_direction * speed
	move_and_slide()

func get_input():
	if Input.is_action_pressed("left"):
		next_movement_direction = Vector2.LEFT
		rotation_degrees = 0
	elif Input.is_action_pressed("right"):
		next_movement_direction = Vector2.RIGHT
		rotation_degrees = 180
	elif Input.is_action_pressed("down"):
		next_movement_direction = Vector2.DOWN
		rotation_degrees = 270
	elif Input.is_action_pressed("up"):
		next_movement_direction = Vector2.UP
		rotation_degrees = 90

func can_move_in_direction(dir: Vector2, delta: float) -> bool:
	shape_query.transform = global_transform.translated(dir * speed * delta * 2)
	var result = get_world_2d().direct_space_state.intersect_shape(shape_query)
	return result.size() == 0

func die():
	if is_dying or is_invulnerable:
		return
	is_dying = true
	if pellets_manager != null and pellets_manager.power_pellet_sound_player != null:
		pellets_manager.power_pellet_sound_player.stop()
	if pacman_death_sound_player != null and !pacman_death_sound_player.playing:
		pacman_death_sound_player.play()
	animation_player.play("death")
	set_physics_process(false)
	set_collision_layer_value(1, false)

func _on_animation_player_animation_finished(anim_name):
	if anim_name != "death":
		return
	lifes -= 1
	if ui != null:
		ui.set_lifes(lifes)  # Aktualizácia životov v UI
		if lifes <= 0:
			ui.game_lost()  # Ak životy klesnú na 0, zobrazí Game Over screen
	else:
		push_error("UI node is not set. Cannot update lives. Cannot show Game Over.")
	player_died.emit(lifes)
	is_dying = false
	if lifes > 0:
		reset_player()  # Reštart hráča, ak ešte má životy
	else:
		set_physics_process(false)  # Vypnutie fyziky, ak sú životy na 0
