extends CharacterBody2D

const GRAVITY := 500.0
const STAIN_SCENE = preload("res://scenes/systems/stain/stain.tscn")
const SPLASH_SCENE = preload("res://scenes/systems/splash/splash.tscn")

func launch(direction: Vector2, speed: float) -> void:
	velocity = direction * speed


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	rotation = velocity.angle()
	var collision := move_and_collide(velocity * delta)
	if collision:
		_on_impact(collision.get_position())
		queue_free()

func _on_impact(impact_pos: Vector2) -> void:
	var splash := SPLASH_SCENE.instantiate()
	splash.global_position = impact_pos
	get_tree().current_scene.add_child(splash)

	if StainSystem.can_spawn_stain(impact_pos):
		var stain := STAIN_SCENE.instantiate()
		stain.global_position = impact_pos
		get_tree().current_scene.add_child(stain)
