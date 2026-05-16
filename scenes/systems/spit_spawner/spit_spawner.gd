extends Node2D

const SPIT_SCENE = preload("res://scenes/systems/split/split.tscn")
const SPIT_SPEED := 300.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_fire(get_global_mouse_position())

func _fire(target: Vector2) -> void:
	var direction := (target - global_position).normalized()
	var spit := SPIT_SCENE.instantiate()
	spit.global_position = global_position
	spit.velocity = direction * SPIT_SPEED
	get_tree().current_scene.add_child(spit)
