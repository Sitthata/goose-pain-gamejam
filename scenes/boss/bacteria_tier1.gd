class_name BacteriaTier1
extends CharacterBody2D

## Tier 1 bacteria enemy.
## Chases player, spits projectile periodically, bursts into spit on death.
## Exported stats are tuned in the Inspector — no hardcoded values in logic.

signal defeated

const SPIT_SCENE = preload("res://scenes/systems/split/split.tscn")
const STAIN_SCENE = preload("res://scenes/systems/stain/stain.tscn")

#region State Machine
enum State { IDLE, CHASE, ATTACK, DEAD, LUNGE, DODGE }

var state: State = State.IDLE : set = set_state
var previous_state: State = State.IDLE
#endregion

#region Export Variables
@export_group("Movement")
@export var move_speed: float = 80.0
@export var detection_range: float = 400.0
@export var attack_range: float = 150.0

@export_group("Health")
@export var max_health: int = 100
var current_health: int

@export_group("Combat")
@export var projectile_rate: float = 3.0   # seconds between shots
@export var spit_speed: float = 200.0
@export var death_spit_count: int = 2
@export var spit_arc: float = 0.3     # fixed upward bias so gravity gives a natural lob
@export var spit_spread: float = 0.9  # half-angle spread in radians (±0.35 ≈ ±20°)

@export_group("Lunge")
@export var lunge_enabled: bool = false
@export var lunge_cooldown: float = 8.0
@export var lunge_speed: float = 400.0
@export var lunge_stain_count: int = 2
@export var lunge_stain_spacing: float = 40.0  # px between trail stains — must exceed 32px proximity block
@export var lunge_duration: float = 0.4        # seconds the lunge lasts before returning to chase

@export_group("Dodge")
@export var dodge_chance_base: float = 0.0  # 0 = never, 1 = always; scales up with Filth %
@export var dodge_speed: float = 200.0
@export var dodge_duration: float = 0.3
#endregion

#region Node References
@onready var sprite: Sprite2D = $Sprite2D
@onready var _debug_label: Label = $DebugLabel
@onready var _lunge_ray: RayCast2D = $LungeRay
#endregion

#region Internal State
var player: Node2D = null

# Two separate timers as floats — no Timer node needed.
# _attack_cooldown: time until the next shot is allowed (persists across states)
# _attack_pause: how long to stay in ATTACK state before returning to CHASE
var _attack_cooldown: float = 0.0
var _attack_pause: float = 0.0

# Lunge
var _lunge_timer: float = 0.0
var _lunge_direction: float = 0.0
var _lunge_stains_remaining: int = 0
var _lunge_dist_accumulator: float = 0.0  # px traveled since last trail stain
var _lunge_duration_timer: float = 0.0

# Dodge
var _dodge_direction: float = 0.0
var _dodge_timer: float = 0.0

# Kept to safely disconnect signal on death
var _player_signal_ref: Node2D = null
#endregion

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_signal("attack_telegraphed"):
		player.attack_telegraphed.connect(_on_attack_telegraphed)
		_player_signal_ref = player
	set_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_instance_valid(player):
		return

	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_attack_pause = maxf(_attack_pause - delta, 0.0)
	_lunge_timer = maxf(_lunge_timer - delta, 0.0)

	velocity.y += get_gravity().y * delta

	match state:
		State.IDLE:
			_update_idle()
		State.CHASE:
			_update_chase()
		State.ATTACK:
			_update_attack()
		State.LUNGE:
			_update_lunge(delta)
		State.DODGE:
			_update_dodge(delta)

	move_and_slide()


# Placeholder kill key — remove once real hit detection is wired
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_K and event.pressed and not event.echo:
		set_state(State.DEAD)


#region State Machine
func set_state(new_state: State) -> void:
	if state == new_state:
		return
	_exit_state(state)
	previous_state = state
	state = new_state
	_enter_state(state)
	_debug_label.text = State.keys()[state]


func _enter_state(new_state: State) -> void:
	match new_state:
		State.IDLE:
			velocity.x = 0

		State.CHASE:
			pass  # movement handled in _update_chase

		State.ATTACK:
			velocity.x = 0
			_fire_spit()
			_attack_cooldown = projectile_rate  # block next shot
			_attack_pause = 0.5                 # brief stop before returning to chase

		State.LUNGE:
			_lunge_direction = signf(player.global_position.x - global_position.x)
			_lunge_stains_remaining = lunge_stain_count
			_lunge_dist_accumulator = 0.0
			_lunge_duration_timer = lunge_duration
			velocity.y = 0.0

		State.DODGE:
			_dodge_timer = dodge_duration
			# _dodge_direction set by _on_attack_telegraphed before entering this state

		State.DEAD:
			velocity = Vector2.ZERO
			set_process(false)
			set_physics_process(false)
			_on_death()


func _exit_state(old_state: State) -> void:
	if old_state == State.LUNGE:
		_lunge_timer = lunge_cooldown
#endregion


#region State Updates
func _update_idle() -> void:
	velocity.x = 0
	if _dist_to_player() <= detection_range:
		set_state(State.CHASE)


func _update_chase() -> void:
	var dist := _dist_to_player()

	if dist > detection_range:
		set_state(State.IDLE)
		return

	if lunge_enabled and _lunge_timer <= 0.0 and _raycast_clear():
		set_state(State.LUNGE)
		return

	if dist <= attack_range and _attack_cooldown <= 0.0:
		set_state(State.ATTACK)
		return

	# Move toward player, stop when within attack range
	if dist > attack_range:
		var dir := signf(player.global_position.x - global_position.x)
		velocity.x = dir * move_speed
		sprite.flip_h = dir < 0.0
	else:
		velocity.x = 0


func _update_attack() -> void:
	velocity.x = 0
	if _attack_pause <= 0.0:
		set_state(State.CHASE)


func _update_lunge(delta: float) -> void:
	velocity.x = _lunge_direction * lunge_speed

	# Deposit trail stains at fixed spacing intervals
	_lunge_dist_accumulator += abs(velocity.x) * delta
	if _lunge_dist_accumulator >= lunge_stain_spacing and _lunge_stains_remaining > 0:
		_lunge_dist_accumulator = 0.0
		_lunge_stains_remaining -= 1
		_try_spawn_trail_stain()

	_lunge_duration_timer -= delta
	if is_on_wall() or _lunge_duration_timer <= 0.0:
		set_state(State.CHASE)


func _update_dodge(delta: float) -> void:
	velocity.x = _dodge_direction * dodge_speed
	_dodge_timer -= delta
	if _dodge_timer <= 0.0:
		set_state(State.CHASE)
#endregion


#region Combat
func _fire_spit() -> void:
	var spit := SPIT_SCENE.instantiate()
	get_parent().add_child(spit)
	spit.global_position = global_position
	var direction := (player.global_position - global_position).normalized()
	direction = direction.rotated(randf_range(-spit_spread, spit_spread))
	direction.y -= spit_arc  # small fixed upward bias for natural gravity lob
	direction = direction.normalized()
	spit.launch(direction, spit_speed)

func take_damage(damage: int) -> void:
	if state == State.DEAD:
		return
	
	current_health -= damage
	print("Bacteria HP: ", current_health)
	
	if current_health <= 0:
		set_state(State.DEAD)

func _on_death() -> void:
	if is_instance_valid(_player_signal_ref) and _player_signal_ref.has_signal("attack_telegraphed"):
		if _player_signal_ref.attack_telegraphed.is_connected(_on_attack_telegraphed):
			_player_signal_ref.attack_telegraphed.disconnect(_on_attack_telegraphed)
	# TODO: play Explode animation here before queue_free when art is ready
	for i in death_spit_count:
		var spit := SPIT_SCENE.instantiate()
		get_parent().add_child(spit)
		spit.global_position = global_position
		# Random angle in the upward hemisphere (negative Y = up in Godot 2D)
		var angle := randf_range(-PI, 0.0)
		spit.launch(Vector2(cos(angle), sin(angle)), spit_speed)
	defeated.emit()
	queue_free()
#endregion


#region Helpers
func _dist_to_player() -> float:
	return global_position.distance_to(player.global_position)


func _raycast_clear() -> bool:
	var range := _lunge_ray.target_position.length()
	_lunge_ray.target_position = to_local(player.global_position).normalized() * range
	_lunge_ray.force_raycast_update()
	return _lunge_ray.is_colliding() and _lunge_ray.get_collider() == player


func _try_spawn_trail_stain() -> void:
	if not is_on_floor():
		return
	# Raycast down to get exact floor contact point, same as spit impact_pos
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 64.0))
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return
	var floor_pos: Vector2 = result.position
	if StainSystem.can_spawn_stain(floor_pos):
		var stain := STAIN_SCENE.instantiate()
		stain.global_position = floor_pos
		get_tree().current_scene.add_child(stain)


func _get_dodge_chance() -> float:
	return dodge_chance_base


func _on_attack_telegraphed(origin: Vector2) -> void:
	if state in [State.DEAD, State.DODGE, State.LUNGE]:
		return
	if randf() < _get_dodge_chance():
		_dodge_direction = signf(global_position.x - origin.x)
		set_state(State.DODGE)


## Applies a stat config dict from boss_stage. Keys must match exported stat names.
func apply_stats(s: Dictionary) -> void:
	lunge_enabled     = s.lunge
	projectile_rate   = s.spit_cd
	death_spit_count  = s.death_spits
	lunge_cooldown    = s.lunge_cd
	lunge_duration    = s.lunge_dur
	lunge_stain_count = s.lunge_stains
	dodge_chance_base = s.dodge
	print("[Bacteria] tier=%d lunge=%s spit_cd=%.1f death_spits=%d lunge_cd=%.1f lunge_dur=%.1f lunge_stains=%d dodge=%.2f" % [
		s.get("tier", 0), lunge_enabled, projectile_rate, death_spit_count,
		lunge_cooldown, lunge_duration, lunge_stain_count, dodge_chance_base
	])
#endregion
