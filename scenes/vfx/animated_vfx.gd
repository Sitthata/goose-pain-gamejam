extends Node2D

@export var animation_name: String = ""

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.play(animation_name)
	animated_sprite.animation_finished.connect(_on_animation_finished)


func setup(new_animation_name: String, flip: bool = false) -> void:
	animation_name = new_animation_name
	
	if is_node_ready():
		animated_sprite.flip_h = flip
		animated_sprite.play(animation_name)


func _on_animation_finished() -> void:
	queue_free()
