extends CanvasLayer

class_name UI

@onready var center_container = $MarginContainer/CenterContainer
@onready var life_count_label = $MarginContainer/VBoxContainer/LifeCountLabel
@onready var game_score_label = $MarginContainer/VBoxContainer/GameScoreLabel
@onready var game_time_label = $MarginContainer/VBoxContainer/GameTimeLabel
@onready var game_label = $MarginContainer/CenterContainer/Panel/GameLabel

var elapsed_time: float = 0.0  # Uchováva celkový čas hry v sekundách

# Funkcia na aktualizáciu počtu životov v UI
func set_lifes(lifes: int) -> void:
	if life_count_label == null:
		push_error("LifeCountLabel not found in UI!")
		return
	life_count_label.text = "%d up" % lifes

# Funkcia na aktualizáciu skóre v UI (len vizuálne)
func set_score(score: int) -> void:
	if game_score_label != null:
		game_score_label.text = "SCORE: %d" % score
	else:
		push_error("GameScoreLabel not found in UI.")

# Funkcia na aktualizáciu času (len vizuálne)
func update_time(delta: float) -> void:
	elapsed_time += delta
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	if game_time_label != null:
		game_time_label.text = "TIME: %02d:%02d" % [minutes, seconds]
	else:
		push_error("GameTimeLabel not found in UI!")

# Spracovanie prehry (bez ukladania dát)
func game_lost() -> void:
	if center_container == null or game_label == null:
		push_error("UI components for 'Game Lost' are not set!")
		return

	game_label.text = "Game lost"
	center_container.show()
	get_tree().paused = true

	# Po 3 sekundách reštartujeme hru
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	restart_current_scene()

# Spracovanie výhry (bez ukladania dát)
func game_won() -> void:
	if center_container == null or game_label == null:
		push_error("UI components for 'Game Won' are not set!")
		return

	game_label.text = "You won!"
	center_container.show()
	get_tree().paused = true

	# Po 3 sekundách reštartujeme hru
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	restart_current_scene()

# Reštart aktuálnej scény
func restart_current_scene() -> void:
	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path != "":
		get_tree().change_scene_to_file(current_scene.scene_file_path)
	else:
		push_error("Scene restart failed. Invalid scene path.")

# Funkcia volaná každým frame
func _process(delta: float) -> void:
	update_time(delta)

# Inicializácia UI pri štarte hry (bez ukladania skóre)
func _ready() -> void:
	print("UI initialized.")
