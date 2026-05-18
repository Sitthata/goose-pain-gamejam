extends CharacterBody2D

signal attack_telegraphed(origin: Vector2)

## Player controller.
## Handles movement, mode switching, cleaning, skill1 attack sequence, and skill2 drop spin.
## skill1: dash + attack1 -> dash + attack2 -> dash + attack3 -> cooldown.
## skill2: drop_spin -> cooldown.

#region Constants
const CLEAN_PRESSES: int = 10
const CLEAN_AMOUNT: float = 1.0 / CLEAN_PRESSES
#endregion


#region State Machine
enum Mode {
	PHASE1,
	PHASE2
}

enum State {
	MOVE,
	CLEANING,
	ATTACKING,
	SKILL2_ATTACKING,
	SKILL3_ATTACKING
}

var current_mode: Mode = Mode.PHASE1

var state: State = State.MOVE : set = set_state
var previous_state: State = State.MOVE
#endregion


#region Export Variables
@export_group("Movement")
@export var normal_speed: float = 10.0
@export var special_speed: float = 16.0
@export var jump_power: float = 10.0
@export var speed_multiplier: float = 30.0
@export var jump_multiplier: float = -30.0

@export_group("Skill 1")
@export var attack1_damage: int = 20
@export var attack2_damage: int = 25
@export var attack3_damage: int = 35
@export var attack_cooldown: float = 1.0
@export var attack_dash_speed: float = 500.0
@export var attack_dash_duration: float = 0.12
@export var attack_slide_friction: float = 2000.0

@export_group("Skill 2")
@export var skill2_damage: int = 45
@export var skill2_cooldown: float = 3.0
@export var skill2_slide_friction: float = 1800.0

@export_group("Skill 3")
@export var skill3_damage: int = 60
@export var skill3_cooldown: float = 5.0
@export var skill3_dash_distance: float = 300.0
@export var skill3_dash_duration: float = 0.18
@export var skill3_startup_time: float = 0.8
@export var skill3_slide_friction: float = 2200.0
#endregion


#region Node References
@onready var animation_player: AnimationPlayer = $AgentAnimator/AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AgentAnimator/AnimatedSprite2D

@onready var _clean_zone: Area2D = $CleanZone
@onready var _clean_indicator: Label = $CleanIndicator
@onready var _clean_progress_bar: ProgressBar = $CleanProgressBar

@onready var punch_sound: AudioStreamPlayer = $sfx/punch_sound
@onready var impact_sound: AudioStreamPlayer = $sfx/Impact_sound

@onready var hurtbox: Area2D = $AgentAnimator/hurtbox
#endregion


#region Internal State
var direction: float = 0.0
var facing_direction: float = 1.0

# Cleaning
var _nearby_stains: Array = []
var _target_stain = null
var _last_clean_key: String = ""

# Skill 1 attack sequence
var _attack_step: int = 0
var _attack_cooldown_timer: float = 0.0
var _attack_dash_timer: float = 0.0

# Skill 2
var _skill2_cooldown_timer: float = 0.0

# Skill 3
var _skill3_cooldown_timer: float = 0.0
var _skill3_startup_timer: float = 0.0
var _skill3_dash_timer: float = 0.0
var _skill3_has_dashed: bool = false

# Shared combat
var _attack_has_hit: bool = false
var _current_attack_damage: int = 0
#endregion


#region Built-in Functions
func _ready() -> void:
	_clean_zone.area_entered.connect(_on_stain_entered)
	_clean_zone.area_exited.connect(_on_stain_exited)

	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	animation_player.animation_finished.connect(_on_animation_finished)

	_clean_indicator.visible = false
	_clean_progress_bar.visible = false

	set_cleaning_enabled(false)
	set_state(State.MOVE)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_update_cooldowns(delta)

	match state:
		State.MOVE:
			_update_move()
		State.CLEANING:
			_update_cleaning()
		State.ATTACKING:
			_update_attacking(delta)
		State.SKILL2_ATTACKING:
			_update_skill2_attacking(delta)
		State.SKILL3_ATTACKING:
			_update_skill3_attacking(delta)
	
	move_and_slide()
#endregion


#region State Machine
func set_state(new_state: State) -> void:
	if state == new_state:
		return

	_exit_state(state)

	previous_state = state
	state = new_state

	_enter_state(state)


func _enter_state(new_state: State) -> void:
	match new_state:
		State.MOVE:
			pass

		State.CLEANING:
			_enter_cleaning_state()

		State.ATTACKING:
			_enter_attacking_state()

		State.SKILL2_ATTACKING:
			_enter_skill2_attacking_state()

		State.SKILL3_ATTACKING:
			_enter_skill3_attacking_state()

func _exit_state(old_state: State) -> void:
	match old_state:
		State.CLEANING:
			pass

		State.ATTACKING:
			pass

		State.SKILL2_ATTACKING:
			pass
#endregion


#region State Updates
func _update_move() -> void:
	_handle_mode_switch()
	_handle_jump()
	_handle_horizontal_movement()

	if Input.is_action_just_pressed("skill1") and _attack_cooldown_timer <= 0.0:
		_attack_step = 0
		set_state(State.ATTACKING)
		return

	if Input.is_action_just_pressed("skill2") and _skill2_cooldown_timer <= 0.0:
		set_state(State.SKILL2_ATTACKING)
		return

	if not _nearby_stains.is_empty() and Input.is_action_just_pressed("clean"):
		set_state(State.CLEANING)
		return

	if Input.is_action_just_pressed("skill3") and _skill3_cooldown_timer <= 0.0:
		set_state(State.SKILL3_ATTACKING)
		return
	
	_update_movement_animation()


func _update_cleaning() -> void:
	velocity.x = move_toward(velocity.x, 0.0, normal_speed * speed_multiplier)

	if not Input.is_action_pressed("clean"):
		_cancel_cleaning()
		return

	if not is_instance_valid(_target_stain):
		_finish_cleaning()
		return

	var cleaning_animation := _process_cleaning_input()
	_update_cleaning_animation(cleaning_animation)


func _update_attacking(delta: float) -> void:
	if _attack_dash_timer > 0.0:
		_attack_dash_timer -= delta
		velocity.x = facing_direction * attack_dash_speed
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			attack_slide_friction * delta
		)


func _update_skill2_attacking(delta: float) -> void:
	velocity.x = move_toward(
		velocity.x,
		0.0,
		skill2_slide_friction * delta
	)

func _update_skill3_attacking(delta: float) -> void:
	if _skill3_startup_timer > 0.0:
		_skill3_startup_timer -= delta
		velocity.x = move_toward(
			velocity.x,
			0.0,
			skill3_slide_friction * delta
		)
		return

	if not _skill3_has_dashed:
		_skill3_has_dashed = true
		_skill3_dash_timer = skill3_dash_duration

	if _skill3_dash_timer > 0.0:
		_skill3_dash_timer -= delta

		var dash_speed := skill3_dash_distance / skill3_dash_duration
		velocity.x = facing_direction * dash_speed
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			skill3_slide_friction * delta
		)
#endregion


#region Movement
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _handle_mode_switch() -> void:
	if not Input.is_action_just_pressed("switch_mode"):
		return

	if current_mode == Mode.PHASE1:
		current_mode = Mode.PHASE2
	else:
		current_mode = Mode.PHASE1


func _handle_jump() -> void:
	if current_mode != Mode.PHASE2:
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_power * jump_multiplier


func _handle_horizontal_movement() -> void:
	direction = Input.get_axis("move_left", "move_right")

	var current_speed := normal_speed

	if current_mode == Mode.PHASE2:
		current_speed = special_speed

	if direction != 0.0:
		velocity.x = direction * current_speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed * speed_multiplier)

	_update_facing_direction()


func _update_facing_direction() -> void:
	if direction < 0.0:
		facing_direction = -1.0
		sprite.flip_h = true
		hurtbox.scale.x = -1.0

	elif direction > 0.0:
		facing_direction = 1.0
		sprite.flip_h = false
		hurtbox.scale.x = 1.0
#endregion


#region Animation
func _update_movement_animation() -> void:
	if current_mode == Mode.PHASE1:
		if direction != 0.0:
			animation_player.play("walk")
		else:
			animation_player.play("idle")
		return

	if not is_on_floor():
		if velocity.y < 0.0:
			animation_player.play("jump")
		else:
			animation_player.play("fall")
	elif direction != 0.0:
		animation_player.play("run")
	else:
		animation_player.play("phase2_idle")


func _update_cleaning_animation(cleaning_animation: String = "") -> void:
	if cleaning_animation != "":
		animation_player.play(cleaning_animation)
		return

	if animation_player.current_animation == "clean_left" and animation_player.is_playing():
		return

	if animation_player.current_animation == "clean_right" and animation_player.is_playing():
		return

	animation_player.play("clean_idle")


func _get_attack_animation_name() -> String:
	match _attack_step:
		0:
			return "attack1"
		1:
			return "attack2"
		2:
			return "attack3"

	return "attack1"
#endregion


#region Cleaning
func _enter_cleaning_state() -> void:
	_target_stain = _get_closest_stain()

	if not _target_stain:
		set_state(State.MOVE)
		return

	_last_clean_key = ""
	_clean_indicator.visible = false
	_clean_progress_bar.value = 0.0
	_clean_progress_bar.visible = true


func _process_cleaning_input() -> String:
	var pressed_left := Input.is_action_just_pressed("move_left")
	var pressed_right := Input.is_action_just_pressed("move_right")

	if pressed_left and _last_clean_key != "left":
		_last_clean_key = "left"
		_target_stain.advance_clean(CLEAN_AMOUNT)
		_clean_progress_bar.value = _target_stain.cleaning_progress
		return "clean_left"

	elif pressed_right and _last_clean_key != "right":
		_last_clean_key = "right"
		_target_stain.advance_clean(CLEAN_AMOUNT)
		_clean_progress_bar.value = _target_stain.cleaning_progress
		return "clean_right"

	_clean_progress_bar.value = _target_stain.cleaning_progress
	return ""


func _cancel_cleaning() -> void:
	if is_instance_valid(_target_stain):
		_target_stain.reset_clean()

	_clear_cleaning_state()
	set_state(State.MOVE)


func _finish_cleaning() -> void:
	_clear_cleaning_state()
	set_state(State.MOVE)


func _clear_cleaning_state() -> void:
	_target_stain = null
	_last_clean_key = ""
	_clean_progress_bar.visible = false

	if not _nearby_stains.is_empty():
		_clean_indicator.visible = true


func set_cleaning_enabled(enabled: bool) -> void:
	if not enabled and state == State.CLEANING:
		_cancel_cleaning()

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

		var distance := global_position.distance_to(stain.global_position)

		if distance < closest_dist:
			closest_dist = distance
			closest = stain

	return closest
#endregion


#region Combat
func _enter_attacking_state() -> void:
	_start_attack_step()


func _start_attack_step() -> void:
	_attack_has_hit = false
	_attack_dash_timer = attack_dash_duration
	velocity.x = facing_direction * attack_dash_speed

	_set_current_attack_damage()

	var attack_animation := _get_attack_animation_name()
	animation_player.play(attack_animation)

	if is_instance_valid(punch_sound):
		punch_sound.play()

	attack_telegraphed.emit(global_position)


func _enter_skill2_attacking_state() -> void:
	_attack_has_hit = false
	_current_attack_damage = skill2_damage
	velocity.x = 0.0

	animation_player.play("drop_spin")

	if is_instance_valid(punch_sound):
		punch_sound.play()

	attack_telegraphed.emit(global_position)


func _set_current_attack_damage() -> void:
	match _attack_step:
		0:
			_current_attack_damage = attack1_damage
		1:
			_current_attack_damage = attack2_damage
		2:
			_current_attack_damage = attack3_damage
		_:
			_current_attack_damage = attack1_damage


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if state != State.ATTACKING and state != State.SKILL2_ATTACKING and state != State.SKILL3_ATTACKING:
		return

	if _attack_has_hit:
		return

	if not body.has_method("take_damage"):
		return

	_attack_has_hit = true
	body.take_damage(_current_attack_damage, global_position)

	if is_instance_valid(impact_sound):
		impact_sound.play()


func _go_to_next_attack_step() -> void:
	_attack_step += 1

	if _attack_step > 2:
		_end_attack_sequence()
		return

	_start_attack_step()


func _end_attack_sequence() -> void:
	_attack_dash_timer = 0.0
	_attack_step = 0
	_attack_cooldown_timer = attack_cooldown
	set_state(State.MOVE)


func _end_skill2_attack() -> void:
	_skill2_cooldown_timer = skill2_cooldown
	set_state(State.MOVE)


func _update_cooldowns(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer = maxf(_attack_cooldown_timer - delta, 0.0)

	if _skill2_cooldown_timer > 0.0:
		_skill2_cooldown_timer = maxf(_skill2_cooldown_timer - delta, 0.0)
		
	if _skill3_cooldown_timer > 0.0:
		_skill3_cooldown_timer = maxf(_skill3_cooldown_timer - delta, 0.0)

func _enter_skill3_attacking_state() -> void:
	_attack_has_hit = false
	_current_attack_damage = skill3_damage

	_skill3_startup_timer = skill3_startup_time
	_skill3_dash_timer = 0.0
	_skill3_has_dashed = false

	velocity.x = 0.0

	animation_player.play("blink_attack")

	if is_instance_valid(punch_sound):
		punch_sound.play()

	attack_telegraphed.emit(global_position)


func _end_skill3_attack() -> void:
	_skill3_startup_timer = 0.0
	_skill3_dash_timer = 0.0
	_skill3_has_dashed = false
	_skill3_cooldown_timer = skill3_cooldown
	set_state(State.MOVE)
#endregion


#region Signal Callbacks
func _on_stain_entered(area: Area2D) -> void:
	if not area.is_in_group("stain"):
		return

	if not _nearby_stains.has(area):
		_nearby_stains.append(area)

	if state == State.MOVE:
		_clean_indicator.visible = true


func _on_stain_exited(area: Area2D) -> void:
	if not area.is_in_group("stain"):
		return

	_nearby_stains.erase(area)

	if area == _target_stain:
		_cancel_cleaning()

	if _nearby_stains.is_empty():
		_clean_indicator.visible = false


func _on_animation_finished(anim_name: StringName) -> void:
	if state == State.ATTACKING:
		if anim_name != "attack1" and anim_name != "attack2" and anim_name != "attack3":
			return

		_go_to_next_attack_step()
		return

	if state == State.SKILL2_ATTACKING:
		if anim_name != "drop_spin":
			return

		_end_skill2_attack()
		return

	if state == State.SKILL3_ATTACKING:
		if anim_name != "blink_attack":
			return

		_end_skill3_attack()
#endregion
