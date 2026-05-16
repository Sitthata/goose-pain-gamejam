extends CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var speed = 10.0
@export var jump_power = 10.0
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0

var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	Handle_jump(delta)
	Handle_Horizontalmov(delta)
	move_and_slide()
	
func Handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_power * jump_multiplier

func Handle_Horizontalmov(delta: float) -> void:
	direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed * speed_multiplier
		animated_sprite.play("walk")
		
		# Flip sprite depending on direction
		if direction < 0:
			animated_sprite.flip_h = true
		elif direction > 0:
			animated_sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)
		animated_sprite.play("idle")
