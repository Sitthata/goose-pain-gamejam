extends CharacterBody2D

const CLEAN_PRESSES: int = 10
const CLEAN_AMOUNT: float = 1.0 / CLEAN_PRESSES

enum Mode {
	PHASE1,
	PHASE2
}

enum State {
	MOVE,
	CLEANING
}

@export var normal_speed = 10.0
@export var special_speed = 16.0
@export var jump_power = 10.0

@onready var animation_player: AnimationPlayer = $AgentAnimator/AnimationPlayer
@onready var sprite: Sprite2D = $AgentAnimator/Sprite2D
@onready var _clean_zone: Area2D = $CleanZone
@onready var _clean_indicator: Label = $CleanIndicator
@onready var _clean_progress_bar: ProgressBar = $CleanProgressBar

var current_mode: Mode = Mode.PHASE1
var _state: State = State.MOVE

var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0

var _nearby_stains: Array = []
var _target_stain = null
var _last_clean_key: String = ""


func _ready() -> void:
	_clean_zone.area_entered.connect(_on_stain_entered)
	_clean_zone.area_exited.connect(_on_stain_exited)
	
	_clean_indicator.visible = false
	_clean_progress_bar.visible = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match _state:
		State.MOVE:
			_state_move(delta)
		State.CLEANING:
			_state_cleaning(delta)

	move_and_slide()


func _state_move(delta: float) -> void:
	handle_mode_switch()
	handle_jump()
	handle_horizontal_movement()
	update_animation()

	if not _nearby_stains.is_empty() and Input.is_action_just_pressed("clean"):
		_start_cleaning()


func _state_cleaning(_delta: float) -> void:
	# Stop the player while cleaning
	velocity.x = move_toward(velocity.x, 0, normal_speed * speed_multiplier)

	if not Input.is_action_pressed("clean"):
		_cancel_clean()
		return

	if not is_instance_valid(_target_stain):
		_finish_clean()
		return

	var pressed_left := Input.is_action_just_pressed("move_left")
	var pressed_right := Input.is_action_just_pressed("move_right")

	if pressed_left and _last_clean_key != "left":
		_last_clean_key = "left"
		_target_stain.advance_clean(CLEAN_AMOUNT)
	elif pressed_right and _last_clean_key != "right":
		_last_clean_key = "right"
		_target_stain.advance_clean(CLEAN_AMOUNT)

	_clean_progress_bar.value = _target_stain.cleaning_progress

	# Optional cleaning animation
	if current_mode == Mode.PHASE1:
		animation_player.play("clean")
	else:
		animation_player.play("phase2_clean")


func handle_mode_switch() -> void:
	if Input.is_action_just_pressed("switch_mode"):
		if current_mode == Mode.PHASE1:
			current_mode = Mode.PHASE2
		else:
			current_mode = Mode.PHASE1


func handle_jump() -> void:
	# Player can only jump in PHASE2
	if current_mode == Mode.PHASE2:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_power * jump_multiplier


func handle_horizontal_movement() -> void:
	direction = Input.get_axis("move_left", "move_right")

	var current_speed = normal_speed

	if current_mode == Mode.PHASE2:
		current_speed = special_speed

	if direction:
		velocity.x = direction * current_speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * speed_multiplier)

	if direction < 0:
		sprite.flip_h = true
	elif direction > 0:
		sprite.flip_h = false


func update_animation() -> void:
	if current_mode == Mode.PHASE1:
		if direction != 0:
			animation_player.play("walk")
		else:
			animation_player.play("idle")

	elif current_mode == Mode.PHASE2:
		if not is_on_floor():
			if velocity.y < 0:
				animation_player.play("jump")
			else:
				animation_player.play("fall")
		elif direction != 0:
			animation_player.play("run")
		else:
			animation_player.play("phase2_idle")


func _start_cleaning() -> void:
	_target_stain = _get_closest_stain()

	if _target_stain:
		_last_clean_key = ""
		_clean_indicator.visible = false
		_clean_progress_bar.value = 0.0
		_clean_progress_bar.visible = true
		_state = State.CLEANING


func _get_closest_stain() -> Area2D:
	var closest = null
	var closest_dist := INF

	for stain in _nearby_stains:
		if not is_instance_valid(stain):
			continue

		var d := global_position.distance_to(stain.global_position)

		if d < closest_dist:
			closest_dist = d
			closest = stain

	return closest


func _cancel_clean() -> void:
	if is_instance_valid(_target_stain):
		_target_stain.reset_clean()

	_target_stain = null
	_last_clean_key = ""
	_clean_progress_bar.visible = false
	_state = State.MOVE

	if not _nearby_stains.is_empty():
		_clean_indicator.visible = true


func _finish_clean() -> void:
	_target_stain = null
	_last_clean_key = ""
	_clean_progress_bar.visible = false
	_state = State.MOVE

	if not _nearby_stains.is_empty():
		_clean_indicator.visible = true


func _on_stain_entered(area: Area2D) -> void:
	if area.is_in_group("stain"):
		_nearby_stains.append(area)

		if _state == State.MOVE:
			_clean_indicator.visible = true


func _on_stain_exited(area: Area2D) -> void:
	if area.is_in_group("stain"):
		_nearby_stains.erase(area)

		if area == _target_stain:
			_cancel_clean()

		if _nearby_stains.is_empty():
			_clean_indicator.visible = false
