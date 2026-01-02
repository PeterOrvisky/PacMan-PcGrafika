extends Sprite2D

class_name BodySprite

@onready var animation_player = $"../AnimationPlayer"
var starting_texture: Texture2D

func _ready():
	move()

func move():
	texture = starting_texture

	# Skontrolujeme, či rodič má správne inicializovanú vlastnosť `color`
	var parent = get_parent()
	if parent is Ghost and parent.has_meta("color"):
		self.modulate = parent.color
	else:
		push_error("Parent does not have a valid 'color'. Defaulting to white.")
		self.modulate = Color.WHITE  # Opravené na Color.WHITE

	animation_player.play("moving")

func run_away():
	self.modulate = Color.WHITE
	animation_player.play("running_away")

func start_blinking():
	animation_player.play("blinking")

func stop_blinking():
	# Stop blinking and return to normal appearance
	move()
