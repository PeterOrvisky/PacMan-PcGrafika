extends Node2D

@onready var right_area_2d = $RightColorRect/Area2D
@onready var left_area_2d = $LeftColorRect/Area2D

var allow_left_transition = true
var allow_right_transition = true

func _on_right_area_2d_body_entered(body):
	if body.velocity.x > 0:
		body.position.x = left_area_2d.global_position.x
		allow_left_transition = false

func _on_right_area_2d_body_exited(body):
	allow_right_transition = true

func _on_left_area_2d_body_entered(body):
	if body.velocity.x < 0: 
		body.position.x = right_area_2d.global_position.x
		allow_right_transition = false

func _on_left_area_2d_body_exited(body):
	allow_left_transition = true
