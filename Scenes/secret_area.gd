extends Area2D

signal secret_entered  # Signal pre tajnú oblasť

var correct_sequence = ["up", "down", "left", "right"]  # Správna sekvencia tlačidiel
var current_sequence = []  # Sledovanie aktuálnych vstupov hráča

@export var secret_scene: PackedScene  # Tajná scéna, ktorú priradíš v inšpektore

func _ready():
	# Pripojenie signálov pre vstupy do oblasti
	connect("body_entered", Callable(self, "_on_player_entered"))
	connect("body_exited", Callable(self, "_on_player_exited"))

	# Aktivuj spracovanie globálnych vstupov
	set_process_input(true)

func _on_player_entered(body):
	if body is Player:
		print("Player entered secret area.")

func _on_player_exited(body):
	if body is Player:
		print("Player exited secret area.")

# Spracovávanie vstupov
func _input(event):
	# Skontroluj, že ide o InputEventKey
	if not (event is InputEventKey and event.pressed):
		return

	# Extrahuje text reprezentujúci stlačenú klávesu
	var key_name = event.as_text()
	current_sequence.append(key_name)

	# Obmedz sekvenciu na maximálnu dĺžku správnej sekvencie
	if current_sequence.size() > correct_sequence.size():
		current_sequence.pop_front()

	# Overenie, či aktuálna sekvencia zodpovedá správnej
	if current_sequence == correct_sequence:
		print("Correct secret activated!")
		secret_entered.emit()  # Emituj signál pre prechod do tajnej oblasti
		current_sequence.clear()
