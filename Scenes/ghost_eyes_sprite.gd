extends Sprite2D

class_name EyesSprite

@export_group("Eye Textures")
@export var up: Texture2D
@export var down: Texture2D
@export var left: Texture2D
@export var right: Texture2D
@export_group("")

@onready var direction_lookup_table = {
	"down": down,
	"up": up,
	"left": left,
	"right": right
}

func _ready():
	# Skontroluj, či je rodič triedy Ghost a pripoj signál bezpečne
	var parent = get_parent()
	if parent is Ghost:
		parent.direction_change.connect(on_direction_change)
	else:
		push_error("EyesSprite's parent is not of type Ghost! Unable to connect direction_change signal.")

# Zmena textúry očí podľa smeru
func on_direction_change(direction: String):
	if direction in direction_lookup_table:
		texture = direction_lookup_table[direction]
	else:
		push_error("Invalid direction '%s' received in EyesSprite." % direction)

func hide_eyes():
	hide()

func show_eyes():
	show()
