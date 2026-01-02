extends Node

func _ready():
	print("Welcome to Scene-2!")
	# Ak by si chcel nastaviť hráčovu pozíciu alebo niečo špecifické:
	var player = get_node("Player")  # Predpokladáme, že node s menom Player existuje
	if player:
		player.position = Vector2(100, 200)  # Nastav novú pozíciu pre hráča (príklad)
