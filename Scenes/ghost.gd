extends Area2D

class_name Ghost

# Signal emitted when run away timer times out
signal run_away_timeout

# ENUM pre stavy ducha
enum GhostState {
	SCATTER,
	CHASE,
	RUN_AWAY,
	EATEN,
	STARTING_AT_HOME
}

@export var color: Color = Color.WHITE  # Predvolená farba pre ducha
@export var scatter_wait_time = 8
@export var eaten_speed = 240
@export var speed = 120
@export var movement_targets: Resource
@export var tile_map: MazeTileMap
@export var chasing_target: Node2D
@export var is_starting_at_home = false
@export var starting_position: Node2D

@onready var eyes_sprite = $EyesSprite
@onready var body_sprite = $BodySprite
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var scatter_timer = $ScatterTimer
@ontml:parameter name="run_away_timer = $RunAwayTimer
@onready var update_chasing_target_position_timer = $UpdateChasingTargetPositionTimer
@onready var at_home_timer = $AtHomeTimer

var current_state: GhostState = GhostState.SCATTER
var current_scatter_index = 0
var current_at_home_index = 0
var is_blinking = false

# Inicializácia (pri načítaní scény)
func _ready():
	call_deferred("setup")

# Spracovanie správania ducha každý snímok
func _process(delta):
	if current_state != GhostState.EATEN:
		move_ghost(navigation_agent_2d.get_next_path_position(), delta)

### Nastavenie ducha
func setup():
	# If movement_targets resource not assigned, try to find markers from scene
	if movement_targets == null:
		print("Movement targets resource not assigned, attempting to find from scene nodes...")
		# Try to find movement target nodes based on ghost name
		var ghost_name = name  # e.g., "RedGhost", "YellowGhost"
		var targets_path = "../../MovementTargets/" + ghost_name
		var targets_node = get_node_or_null(targets_path)
		if targets_node:
			# Create a runtime movement targets object
			movement_targets = MovementTargets.new()
			
			# Get scatter targets
			var scatter_node = targets_node.get_node_or_null("Scatter")
			if scatter_node:
				movement_targets.scatter_targets = scatter_node.get_children()
			
			# Get at home targets
			var home_node = targets_node.get_node_or_null("Home")
			if home_node:
				movement_targets.at_home_targets = home_node.get_children()
			
			print("Movement targets loaded from scene for " + ghost_name)
		else:
			push_error("Setup failed! Could not find movement targets for " + ghost_name)
			return

	# Inicializácia navigácie
	if tile_map:
		navigation_agent_2d.set_navigation_map(tile_map.get_navigation_map(0))
	else:
		push_error("TileMap not assigned to Ghost!")

	position = starting_position.position
	current_state = GhostState.SCATTER

	# Povolenie kolízií
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

	eyes_sprite.show_eyes()
	body_sprite.move()

	if is_starting_at_home:
		start_at_home()
	else:
		scatter()

### SCATTER stav
func scatter():
	if movement_targets == null or movement_targets.scatter_targets.size() == 0:
		push_error("No scatter_targets assigned to Ghost.")
		return

	current_state = GhostState.SCATTER
	update_chasing_target_position_timer.stop()  # Stop chase timer during scatter
	update_scatter_target()
	scatter_timer.start()

### RUN_AWAY stav po zjedení veľkého pelletu
func on_big_pellet_eaten(duration: float):
	if current_state == GhostState.RUN_AWAY:
		extend_runaway_time(duration)  # Predĺžiť RUN_AWAY čas
	elif current_state != GhostState.EATEN:
		run_away_from_pacman()

func extend_runaway_time(duration: float):
	run_away_timer.start(run_away_timer.time_left + duration)
	print("Runaway time extended. New time: %fs" % run_away_timer.time_left)

func run_away_from_pacman():
	run_away_timer.start()
	current_state = GhostState.RUN_AWAY
	body_sprite.start_blinking()
	update_chasing_target_position_timer.stop()  # Stop chase timer when running away
	print("Ghost set to RUN_AWAY state.")
	update_scatter_target()

### Návrat TELA ducha na domácu pozíciu (respawn)
func respawn_body_at_home():
	print("Ghost respawn @ home. Transitioning back to CHASE state.")
	current_state = GhostState.CHASE
	body_sprite.show()
	body_sprite.move()
	eyes_sprite.show_eyes()
	set_collision_mask_value(1, false)

	await get_tree().create_timer(1.5).timeout  # Ochranná doba
	set_collision_mask_value(1, true)
	start_chasing_pacman()

### Pohyb do štartovacej oblasti
func start_at_home():
	if movement_targets == null or movement_targets.at_home_targets.size() == 0:
		push_error("Ghost error: at_home_targets not assigned or empty.")
		return
	
	current_state = GhostState.STARTING_AT_HOME
	current_at_home_index = 0  # Začíname na prvom "domácom" bode

	# Nastavenie cieľa pre navigáciu v agentovi
	navigation_agent_2d.target_position = movement_targets.at_home_targets[current_at_home_index].position
	at_home_timer.start()  # Start timer to eventually leave home
	print("Ghost moving within home area.")

### Prenasledovanie pacmana (CHASE stav)
func start_chasing_pacman():
	if chasing_target == null:
		push_error("Chasing target not assigned to Ghost!")
		return
	current_state = GhostState.CHASE
	navigation_agent_2d.target_position = chasing_target.position
	update_chasing_target_position_timer.start()
	print("Ghost is now chasing the player.")

### Pohyb ducha smerom k cieľu
func move_ghost(next_position: Vector2, delta: float):
	var current_speed = eaten_speed if current_state == GhostState.EATEN else speed
	var new_velocity = (next_position - global_position).normalized() * current_speed * delta
	position += new_velocity

### Aktualizácia scatter targeta
func update_scatter_target():
	if movement_targets == null or movement_targets.scatter_targets.size() == 0:
		push_error("Scatter targets incorrectly configured!")
		return

	navigation_agent_2d.target_position = movement_targets.scatter_targets[current_scatter_index].position
	current_scatter_index = (current_scatter_index + 1) % movement_targets.scatter_targets.size()

### Signal handler: Scatter timer timeout
func _on_scatter_timer_timeout():
	if current_state == GhostState.SCATTER:
		start_chasing_pacman()
		print("Ghost switching from SCATTER to CHASE state.")

### Signal handler: Run away timer timeout
func _on_run_away_timer_timeout():
	if current_state == GhostState.RUN_AWAY:
		body_sprite.stop_blinking()
		body_sprite.move()
		current_state = GhostState.CHASE
		run_away_timeout.emit()  # Emit signal for pellets_manager
		print("Ghost run away time expired. Switching to CHASE state.")
		start_chasing_pacman()

### Signal handler: Update chasing target position
func _on_update_chasing_target_position_timer_timeout():
	if current_state == GhostState.CHASE and chasing_target != null:
		navigation_agent_2d.target_position = chasing_target.position

### Signal handler: Body entered collision
func _on_body_entered(body):
	if body is Player:
		if current_state == GhostState.RUN_AWAY:
			# Ghost is eaten by player
			print("Ghost eaten by player!")
			current_state = GhostState.EATEN
			body_sprite.hide()
			eyes_sprite.show_eyes()
			set_collision_mask_value(1, false)
			run_away_timer.stop()
			# Navigate back home
			navigation_agent_2d.target_position = starting_position.position
			await get_tree().create_timer(0.5).timeout
			respawn_body_at_home()
		elif current_state != GhostState.EATEN:
			# Player is caught by ghost
			print("Player caught by ghost!")
			body.die()

### Signal handler: At home timer timeout
func _on_at_home_timer_timeout():
	if current_state == GhostState.STARTING_AT_HOME:
		print("Ghost leaving home area, starting to chase.")
		start_chasing_pacman()
