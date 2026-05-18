extends CharacterBody2D

signal attack_telegraphed(origin: Vector2)

#region Constants
const CLEAN_PRESSES: int = 10
const CLEAN_AMOUNT: float = 1.0 / CLEAN_PRESSES
const ANIMATED_VFX = preload("res://scenes/vfx/animated_vfx.tscn")
#endregion


#region State Machine
enum Mode {
	PHASE1,
	PHASE2
}

enum State {
	MOVE,
	CLEANING,
	ATTACKING
}

var current_mode: Mode = Mode.PHASE1
var _state: State = State.MOVE
#endregion


#region Export Variables
@export_group("Movement")
@export var normal_speed = 10.0
@export var special_speed = 16.0
@export var jump_power = 10.0

@export_group("Combat")
@export var punch_damage: int = 25
#endregion


#region Node References
@onready var animation_player: AnimationPlayer = $AgentAnimator/AnimationPlayer
@onready var sprite: Sprite2D = $AgentAnimator/Sprite2D

@onready var _clean_zone: Area2D = $CleanZone
@onready var _clean_indicator: Label = $CleanIndicator
@onready var _clean_progress_bar: ProgressBar = $CleanProgressBar

@onready var punch_sound: AudioStreamPlayer = $sfx/punch_sound
@onready var impact_sound: AudioStreamPlayer = $sfx/Impact_sound

@onready var punch_hit: Area2D = $AgentAnimator/punch_hit
#endregion


#region Internal State
var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0

var _nearby_stains: Array = []
var _target_stain = null
var _last_clean_key: String = ""
var punch_hit_start_x: float
#endregion


#region Built-in Functions
func _ready() -> void:
	_clean_zone.area_entered.connect(_on_stain_entered)
	_clean_zone.area_exited.connect(_on_stain_exited)

	punch_hit_start_x = punch_hit.position.x
	punch_hit.body_entered.connect(_on_punch_hit_body_entered)
	animation_player.animation_finished.connect(_on_animation_finished)

	_clean_indicator.visible = false
	_clean_progress_bar.visible = false
	set_cleaning_enabled(false)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match _state:
		State.MOVE:
			_state_move(delta)
		State.CLEANING:
			_state_cleaning(delta)
		State.ATTACKING:
			_state_attacking(delta)

	move_and_slide()
#endregion


#region State Updates
func _state_move(delta: float) -> void:
	handle_mode_switch()
	handle_jump()
	handle_horizontal_movement()

	if Input.is_action_just_pressed("attack"):
		_start_attack()
		return

	update_animation()

	if not _nearby_stains.is_empty() and Input.is_action_just_pressed("clean"):
		_start_cleaning()


func _state_cleaning(_delta: float) -> void:
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

	if current_mode == Mode.PHASE1:
		animation_player.play("clean")
	else:
		animation_player.play("phase2_clean")


func _state_attacking(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, normal_speed * speed_multiplier)
#endregion


#region Movement
func handle_mode_switch() -> void:
	if Input.is_action_just_pressed("switch_mode"):
		if current_mode == Mode.PHASE1:
			current_mode = Mode.PHASE2
		else:
			current_mode = Mode.PHASE1


func handle_jump() -> void:
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
		punch_hit.position.x = -abs(punch_hit_start_x)
	elif direction > 0:
		sprite.flip_h = false
		punch_hit.position.x = abs(punch_hit_start_x)
#endregion


#region Animation
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
#endregion


#region Cleaning
func _start_cleaning() -> void:
	_target_stain = _get_closest_stain()

	if _target_stain:
		_last_clean_key = ""
		_clean_indicator.visible = false
		_clean_progress_bar.value = 0.0
		_clean_progress_bar.visible = true
		_state = State.CLEANING


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


func set_cleaning_enabled(enabled: bool) -> void:
	if not enabled and _state == State.CLEANING:
		_cancel_clean()

	_nearby_stains.clear()
	_clean_indicator.visible = false
	_clean_zone.monitoring = enabled

	if enabled:
		for area in _clean_zone.get_overlapping_areas():
			if area.is_in_group("stain"):
				_nearby_stains.append(area)

		if not _nearby_stains.is_empty():
			_clean_indicator.visible = true


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
#endregion


#region Combat
func _start_attack() -> void:
	_state = State.ATTACKING
	velocity.x = 0
	animation_player.play("punch")
	punch_sound.play()
	attack_telegraphed.emit(global_position)


func _on_punch_hit_body_entered(body: Node2D) -> void:
	if _state != State.ATTACKING:
		return

	if body.has_method("take_damage"):
		body.take_damage(punch_damage, global_position)
		impact_sound.play()
		
		#var impact_position := global_position.lerp(body.global_position, 0.6)
		#var should_flip := body.global_position.x < global_position.x

		#_spawn_vfx("punch_impact_vfx", impact_position, should_flip)
#endregion

#region VFX
func _spawn_vfx(vfx_name: String, spawn_position: Vector2, flip: bool = false) -> void:
	var vfx := ANIMATED_VFX.instantiate()
	get_tree().current_scene.add_child(vfx)
	vfx.global_position = spawn_position
	vfx.setup(vfx_name, flip)
#endregion

#region Signal Callbacks
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


func _on_animation_finished(anim_name: StringName) -> void:
	if _state == State.ATTACKING and anim_name == "punch":
		_state = State.MOVE
#endregion
