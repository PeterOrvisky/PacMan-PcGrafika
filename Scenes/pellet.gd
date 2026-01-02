extends Area2D

class_name PelletLocal

signal pellet_eaten(should_allow_eating_ghosts: bool, score_value: int)

@export var score_value: int = 10  # Skóre za obyčajný pellet
@export var should_allow_eating_ghosts = false  # Označuje, či pellet aktivuje efekt "ghosts eating"

func _on_body_entered(body):
	if body is Player:
		print("Pellet eaten by Player. Power pellet effect: %s, Score Value: %d" % [should_allow_eating_ghosts, score_value])
		pellet_eaten.emit(should_allow_eating_ghosts, score_value)
		queue_free()  # Odstránenie pelleta zo scény
	else:
		print("Non-player body entered pellet.")
