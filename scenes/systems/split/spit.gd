extends CharacterBody2D

const GRAVITY := 500.0
const SPLASH_SCENE = preload("res://scenes/systems/splash/splash.tscn")

func launch(direction: Vector2, speed: float) -> void:
	velocity = direction * speed


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	rotation = velocity.angle()
	var collision := move_and_collide(velocity * delta)
	if collision:
		_on_impact(collision.get_position(), collision.get_normal())
		queue_free()

func _on_impact(impact_pos: Vector2, surface_normal: Vector2) -> void:
	var splash := SPLASH_SCENE.instantiate()
	splash.global_position = impact_pos
	get_tree().current_scene.add_child(splash)

	StainSystem.spawn_stain(impact_pos, surface_normal)
