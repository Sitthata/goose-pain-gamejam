class_name BacteriaTier1
extends CharacterBody2D

## Tier 1 bacteria enemy.
## Fights the Room — goal is to fill Filth Gauge via Stains.
## Avoids The Goose; LUNGE is the only intentional approach move.
## Exported stats tuned in Inspector. Zone radii tuned on JumpZone/DodgeZone child nodes.

signal defeated

const SPIT_SCENE = preload("res://scenes/systems/split/split.tscn")

#region State Machine
enum State { IDLE, ROAM, ATTACK, DEAD, LUNGE, DODGE, JUMP, GROUND_SLAM }

var state: State = State.IDLE : set = set_state
var previous_state: State = State.IDLE
#endregion

#region Export Variables
@export_group("Movement")
@export var move_speed: float = 80.0
@export var detection_range: float = 400.0
@export var attack_range: float = 150.0       # safe distance to maintain from The Goose during ROAM
@export var room_half_width: float = 600.0    # used to detect wall proximity for JUMP direction

@export_group("Health")
@export var max_health: int = 100
var current_health: int

@export_group("Combat")
@export var knockback_force: float = 300.0
@export var projectile_rate: float = 3.0   # seconds between shots
@export var spit_speed: float = 200.0
@export var death_spit_count: int = 2
@export var spit_arc: float = 0.3          # fixed upward bias so gravity gives a natural lob
@export var spit_spread: float = 0.9       # half-angle spread in radians

@export_group("Lunge")
@export var lunge_enabled: bool = false
@export var lunge_cooldown: float = 8.0
@export var lunge_speed: float = 400.0
@export var lunge_stain_count: int = 2
@export var lunge_stain_spacing: float = 40.0
@export var lunge_duration: float = 0.4

@export_group("Dodge")
@export var dodge_chance_base: float = 0.0
@export var dodge_speed: float = 200.0
@export var dodge_duration: float = 0.3

@export_group("Jump")
@export var jump_enabled: bool = false
@export var jump_speed_x: float = 250.0
@export var jump_speed_y: float = -400.0
@export var jump_cooldown: float = 3.0

@export_group("Ground Slam")
@export var slam_enabled: bool = false
@export var slam_cooldown: float = 14.0
@export var slam_stain_count: int = 5
@export var slam_spit_count: int = 4
@export var slam_rise_speed: float = -500.0
#endregion

#region Node References
@onready var sprite: Sprite2D = $AgentAnimator/Sprite2D
@onready var _debug_label: Label = $DebugLabel
@onready var _lunge_ray: RayCast2D = $LungeRay
@onready var animation_player: AnimationPlayer = $AgentAnimator/AnimationPlayer
@onready var _jump_zone: Area2D = $JumpZone
@onready var _dodge_zone: Area2D = $DodgeZone
#endregion

#region Internal State
var player: Node2D = null
var _room_center_x: float = 0.0

# Timers
var _attack_cooldown: float = 0.0
var _attack_pause: float = 0.0
var _lunge_timer: float = 0.0
var _jump_timer: float = 0.0
var _slam_timer: float = 0.0

# Lunge
var _lunge_direction: float = 0.0
var _lunge_stains_remaining: int = 0
var _lunge_dist_accumulator: float = 0.0
var _lunge_duration_timer: float = 0.0

# Dodge
var _dodge_direction: float = 0.0
var _dodge_timer: float = 0.0
var _player_in_dodge_zone: bool = false

# Jump
var _jump_direction: float = 0.0
var _jump_left_floor: bool = false
var _player_in_jump_zone: bool = false

# Ground Slam
var _slam_left_floor: bool = false
var _wall_escape_timer: float = 0.0

var _invincible: bool = false
var _knockback_timer: float = 0.0
var _knockback_vx: float = 0.0
var _player_signal_ref: Node2D = null
#endregion


func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")

	var room_center := get_tree().get_first_node_in_group("room_center")
	if is_instance_valid(room_center):
		_room_center_x = room_center.global_position.x

	if is_instance_valid(player) and player.has_signal("attack_telegraphed"):
		player.attack_telegraphed.connect(_on_attack_telegraphed)
		_player_signal_ref = player

	_jump_zone.body_entered.connect(_on_jump_zone_body_entered)
	_jump_zone.body_exited.connect(_on_jump_zone_body_exited)
	_dodge_zone.body_entered.connect(_on_dodge_zone_body_entered)
	_dodge_zone.body_exited.connect(_on_dodge_zone_body_exited)

	_slam_timer = slam_cooldown  # don't slam immediately on spawn
	set_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_instance_valid(player):
		return

	_attack_cooldown    = maxf(_attack_cooldown    - delta, 0.0)
	_attack_pause       = maxf(_attack_pause       - delta, 0.0)
	_lunge_timer        = maxf(_lunge_timer        - delta, 0.0)
	_jump_timer         = maxf(_jump_timer         - delta, 0.0)
	_slam_timer         = maxf(_slam_timer         - delta, 0.0)
	_knockback_timer    = maxf(_knockback_timer    - delta, 0.0)
	_wall_escape_timer  = maxf(_wall_escape_timer  - delta, 0.0)

	velocity.y += get_gravity().y * delta

	set_state(_desired_state())

	match state:
		State.IDLE:
			_update_idle()
		State.ROAM:
			_update_roam()
		State.ATTACK:
			_update_attack()
		State.LUNGE:
			_update_lunge(delta)
		State.DODGE:
			_update_dodge(delta)
		State.JUMP:
			_update_jump()
		State.GROUND_SLAM:
			_update_ground_slam()

	# Knockback overrides state velocity after the state update runs
	if _knockback_timer > 0.0:
		velocity.x = _knockback_vx

	move_and_slide()


## Returns the state the FSM wants to be in. Priority is explicit top-to-bottom.
## Locked states (DEAD, LUNGE, DODGE, ATTACK, JUMP, GROUND_SLAM) handle their own exits.
func _desired_state() -> State:
	if state in [State.DEAD, State.LUNGE, State.DODGE, State.ATTACK, State.JUMP, State.GROUND_SLAM]:
		return state
	if not is_instance_valid(player):
		return State.IDLE
	if _dist_to_player() > detection_range:
		return State.IDLE
	if jump_enabled and _player_in_jump_zone and _jump_timer <= 0.0:
		return State.JUMP
	if _attack_cooldown <= 0.0:
		return State.ATTACK
	if lunge_enabled and _lunge_timer <= 0.0 and _raycast_clear():
		return State.LUNGE
	if slam_enabled and _slam_timer <= 0.0 and is_on_floor():
		return State.GROUND_SLAM
	return State.ROAM


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

		State.ROAM:
			pass

		State.ATTACK:
			velocity.x = 0
			_fire_spit()
			_attack_cooldown = projectile_rate
			_attack_pause = 0.5

		State.LUNGE:
			_lunge_direction = signf(player.global_position.x - global_position.x)
			_lunge_stains_remaining = lunge_stain_count
			_lunge_dist_accumulator = 0.0
			_lunge_duration_timer = lunge_duration
			velocity.y = 0.0

		State.DODGE:
			_dodge_timer = dodge_duration

		State.JUMP:
			_jump_direction = _pick_jump_direction()
			velocity.x = _jump_direction * jump_speed_x
			velocity.y = jump_speed_y
			_jump_left_floor = false
			sprite.flip_h = _jump_direction < 0.0

		State.GROUND_SLAM:
			velocity.x = 0
			velocity.y = slam_rise_speed
			_slam_left_floor = false

		State.DEAD:
			velocity = Vector2.ZERO
			set_process(false)
			set_physics_process(false)
			_on_death()


func _exit_state(old_state: State) -> void:
	match old_state:
		State.LUNGE:
			_lunge_timer = lunge_cooldown
		State.JUMP:
			_jump_timer = jump_cooldown
		State.GROUND_SLAM:
			_slam_timer = slam_cooldown
#endregion


#region State Updates
func _update_idle() -> void:
	velocity.x = 0


func _update_roam() -> void:
	# Wall escape — commit to moving toward room center for a short duration
	# so the stain logic can't immediately reverse direction and cause oscillation
	if is_on_wall():
		_wall_escape_timer = 0.4
	if _wall_escape_timer > 0.0:
		var escape_dir := signf(_room_center_x - global_position.x)
		velocity.x = escape_dir * move_speed
		sprite.flip_h = escape_dir < 0.0
		return

	# Count stains on each side of the room to find the cleaner side
	var left_count := 0
	var right_count := 0
	for stain in StainSystem.active_stains:
		if stain.global_position.x < _room_center_x:
			left_count += 1
		else:
			right_count += 1

	var target_dir: float
	if left_count < right_count:
		target_dir = -1.0
	elif right_count < left_count:
		target_dir = 1.0
	else:
		# Equal — move away from player
		target_dir = signf(global_position.x - player.global_position.x)

	# Hold position if player is between bacteria and the target side
	var to_player_x := player.global_position.x - global_position.x
	if signf(to_player_x) == target_dir and abs(to_player_x) < attack_range:
		velocity.x = 0
	else:
		velocity.x = target_dir * move_speed
		sprite.flip_h = target_dir < 0.0


func _update_attack() -> void:
	velocity.x = 0
	if _attack_pause <= 0.0:
		set_state(State.ROAM)


func _update_lunge(delta: float) -> void:
	velocity.x = _lunge_direction * lunge_speed

	_lunge_dist_accumulator += abs(velocity.x) * delta
	if _lunge_dist_accumulator >= lunge_stain_spacing and _lunge_stains_remaining > 0:
		_lunge_dist_accumulator = 0.0
		_lunge_stains_remaining -= 1
		_try_spawn_trail_stain()

	_lunge_duration_timer -= delta
	if is_on_wall() or _lunge_duration_timer <= 0.0:
		set_state(State.ROAM)


func _update_dodge(delta: float) -> void:
	velocity.x = _dodge_direction * dodge_speed
	_dodge_timer -= delta
	if _dodge_timer <= 0.0:
		set_state(State.ROAM)


func _update_jump() -> void:
	velocity.x = _jump_direction * jump_speed_x
	# Wait until we have actually left the floor before checking for landing
	if not _jump_left_floor:
		if not is_on_floor():
			_jump_left_floor = true
		return
	if is_on_floor():
		set_state(State.ROAM)


func _update_ground_slam() -> void:
	# Wait until we have left the floor
	if not _slam_left_floor:
		if not is_on_floor():
			_slam_left_floor = true
		return
	# Land detection
	if is_on_floor():
		_on_slam_land()
		set_state(State.ROAM)
#endregion


#region Combat
func _fire_spit() -> void:
	var spit := SPIT_SCENE.instantiate()
	get_parent().add_child(spit)
	spit.global_position = global_position
	var target := _find_clean_floor_target()
	var direction := (target - global_position).normalized()
	direction = direction.rotated(randf_range(-spit_spread, spit_spread))
	direction.y -= spit_arc
	direction = direction.normalized()
	spit.launch(direction, spit_speed)


func _on_slam_land() -> void:
	var space := get_world_2d().direct_space_state
	for i in slam_stain_count:
		var cx := global_position.x + randf_range(-80.0, 80.0)
		var query := PhysicsRayQueryParameters2D.create(
			Vector2(cx, global_position.y),
			Vector2(cx, global_position.y + 64.0)
		)
		query.exclude = [get_rid()]
		var result := space.intersect_ray(query)
		if not result.is_empty():
			StainSystem.spawn_stain(result.position, Vector2.UP)

	# Fire spit in upward arc spread
	for i in slam_spit_count:
		var angle: float = lerpf(-PI, 0.0, float(i) / maxf(slam_spit_count - 1, 1))
		var spit := SPIT_SCENE.instantiate()
		get_parent().add_child(spit)
		spit.global_position = global_position
		spit.launch(Vector2(cos(angle), sin(angle)), spit_speed)


func take_damage(damage: int, hit_origin: Vector2) -> void:
	if state == State.DEAD or _invincible:
		return
	current_health -= damage
	_flash_white()
	_apply_knockback(hit_origin)
	_start_iframes()
	if current_health <= 0:
		set_state(State.DEAD)
		return
	animation_player.play("hit_reaction")


func _flash_white() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(4.0, 4.0, 4.0, 1.0), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _apply_knockback(hit_origin: Vector2) -> void:
	_knockback_vx    = signf(global_position.x - hit_origin.x) * knockback_force
	_knockback_timer = 0.15


func _start_iframes() -> void:
	_invincible = true
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(self):
		_invincible = false


func _on_death() -> void:
	if is_instance_valid(_player_signal_ref) and _player_signal_ref.has_signal("attack_telegraphed"):
		if _player_signal_ref.attack_telegraphed.is_connected(_on_attack_telegraphed):
			_player_signal_ref.attack_telegraphed.disconnect(_on_attack_telegraphed)
	# TODO: play Explode animation here before queue_free when art is ready
	for i in death_spit_count:
		var spit := SPIT_SCENE.instantiate()
		get_parent().add_child(spit)
		spit.global_position = global_position
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


func _pick_jump_direction() -> float:
	# Rule 1: wall escape — if near a wall, jump toward room center
	var dist_from_center := global_position.x - _room_center_x
	if abs(dist_from_center) > room_half_width * 0.7:
		return signf(_room_center_x - global_position.x)

	# Rule 2: jump to cleaner side of room
	var left_count := 0
	var right_count := 0
	for stain in StainSystem.active_stains:
		if stain.global_position.x < _room_center_x:
			left_count += 1
		else:
			right_count += 1

	if left_count < right_count:
		return -1.0
	if right_count < left_count:
		return 1.0
	# Tiebreak: jump away from player
	return signf(global_position.x - player.global_position.x)


func _find_clean_floor_target() -> Vector2:
	var space := get_world_2d().direct_space_state
	for i in 5:
		var cx := global_position.x + randf_range(-attack_range, attack_range)
		var query := PhysicsRayQueryParameters2D.create(
			Vector2(cx, global_position.y),
			Vector2(cx, global_position.y + 128.0)
		)
		query.exclude = [get_rid()]
		var result := space.intersect_ray(query)
		if result.is_empty():
			continue
		if StainSystem.can_spawn_stain(result.position, Vector2.UP):
			return result.position
	return player.global_position  # fallback: all nearby floor is stained


func _try_spawn_trail_stain() -> void:
	if not is_on_floor():
		return
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 64.0))
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return
	StainSystem.spawn_stain(result.position, Vector2.UP)


func _get_dodge_chance() -> float:
	return dodge_chance_base


func _on_attack_telegraphed(origin: Vector2) -> void:
	if state in [State.DEAD, State.DODGE, State.LUNGE, State.JUMP, State.GROUND_SLAM]:
		return
	if not _player_in_dodge_zone:
		return
	if randf() < _get_dodge_chance():
		_dodge_direction = signf(global_position.x - origin.x)
		set_state(State.DODGE)


func _on_jump_zone_body_entered(body: Node2D) -> void:
	if body == player:
		_player_in_jump_zone = true

func _on_jump_zone_body_exited(body: Node2D) -> void:
	if body == player:
		_player_in_jump_zone = false

func _on_dodge_zone_body_entered(body: Node2D) -> void:
	if body == player:
		_player_in_dodge_zone = true

func _on_dodge_zone_body_exited(body: Node2D) -> void:
	if body == player:
		_player_in_dodge_zone = false


func apply_stats(s: BacteriaStats) -> void:
	max_health        = s.max_health
	current_health    = max_health
	lunge_enabled     = s.lunge
	projectile_rate   = s.spit_cd
	death_spit_count  = s.death_spits
	lunge_cooldown    = s.lunge_cd
	lunge_duration    = s.lunge_dur
	lunge_stain_count = s.lunge_stains
	dodge_chance_base = s.dodge
	jump_enabled      = s.jump_enabled
	jump_cooldown     = s.jump_cd
	slam_enabled      = s.slam_enabled
	slam_cooldown     = s.slam_cd
	print("[Bacteria] tier=%d lunge=%s jump=%s slam=%s spit_cd=%.1f dodge=%.2f slam_cd=%.1f" % [
		s.tier, lunge_enabled, jump_enabled, slam_enabled, projectile_rate, dodge_chance_base, slam_cooldown
	])
#endregion
