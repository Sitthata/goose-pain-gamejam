extends CharacterBody2D

const CLEAN_PRESSES: int = 10
const CLEAN_AMOUNT: float = 1.0 / CLEAN_PRESSES

@export var speed = 10.0
@export var jump_power = 10.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _clean_zone: Area2D = $CleanZone
@onready var _clean_indicator: Label = $CleanIndicator
@onready var _clean_progress_bar: ProgressBar = $CleanProgressBar

enum State { MOVE, CLEANING }

var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0

var _state: State = State.MOVE
var _nearby_stains: Array = []
var _target_stain = null
var _last_clean_key: String = ""

func _ready() -> void:
	_clean_zone.area_entered.connect(_on_stain_entered)
	_clean_zone.area_exited.connect(_on_stain_exited)

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
	Handle_jump(delta)
	Handle_Horizontalmov(delta)
	if not _nearby_stains.is_empty() and Input.is_action_just_pressed("clean"):
		_target_stain = _get_closest_stain()
		if _target_stain:
			_last_clean_key = ""
			_clean_indicator.visible = false
			_clean_progress_bar.value = 0.0
			_clean_progress_bar.visible = true
			_state = State.CLEANING

func _state_cleaning(_delta: float) -> void:
	if not Input.is_action_pressed("clean"):
		_cancel_clean()
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

func Handle_jump(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_power * jump_multiplier

func Handle_Horizontalmov(_delta: float) -> void:
	direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed * speed_multiplier
		animated_sprite.play("walk")
		if direction < 0:
			animated_sprite.flip_h = true
		elif direction > 0:
			animated_sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)
		animated_sprite.play("idle")

func _get_closest_stain() -> Area2D:
	var closest = null
	var closest_dist := INF
	for stain in _nearby_stains:
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

func _on_stain_entered(area: Area2D) -> void:
	if area.is_in_group("stain"):
		_nearby_stains.append(area)
		_clean_indicator.visible = true

func _on_stain_exited(area: Area2D) -> void:
	if area.is_in_group("stain"):
		_nearby_stains.erase(area)
		if _nearby_stains.is_empty():
			_clean_indicator.visible = false
			_cancel_clean()
