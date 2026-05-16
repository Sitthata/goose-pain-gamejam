class_name BacteriaTier1
extends CharacterBody2D

## Tier 1 bacteria enemy.
## Chases player, spits projectile periodically, bursts into spit on death.
## Exported stats are tuned in the Inspector — no hardcoded values in logic.

signal defeated

const SPIT_SCENE = preload("res://scenes/systems/split/split.tscn")

#region State Machine
enum State { IDLE, CHASE, ATTACK, DEAD }

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
@export var spit_arc: float = 0.4  # upward bias applied to spit direction (higher = more arc)
#endregion

#region Node References
@onready var sprite: Sprite2D = $Sprite2D
@onready var _debug_label: Label = $DebugLabel
#endregion

#region Internal State
var player: Node2D = null

# Two separate timers as floats — no Timer node needed.
# _attack_cooldown: time until the next shot is allowed (persists across states)
# _attack_pause: how long to stay in ATTACK state before returning to CHASE
var _attack_cooldown: float = 0.0
var _attack_pause: float = 0.0
#endregion

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	set_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_instance_valid(player):
		return

	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_attack_pause = maxf(_attack_pause - delta, 0.0)

	velocity.y += get_gravity().y * delta

	match state:
		State.IDLE:
			_update_idle()
		State.CHASE:
			_update_chase()
		State.ATTACK:
			_update_attack()

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

		State.DEAD:
			velocity = Vector2.ZERO
			set_process(false)
			set_physics_process(false)
			_on_death()


func _exit_state(_old_state: State) -> void:
	pass  # nothing to clean up for Tier 1 states
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
#endregion


#region Combat
func _fire_spit() -> void:
	var spit := SPIT_SCENE.instantiate()
	get_parent().add_child(spit)
	spit.global_position = global_position
	var direction := (player.global_position - global_position).normalized()
	direction.y -= spit_arc  # bias upward so the spit arcs toward the player
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


## Scales exported stats by tier number. Called by boss_stage after instantiation.
## Prototype shortcut — production should use separate scenes per tier with Inspector-tuned values.
func apply_tier(tier: int) -> void:
	move_speed       = move_speed * pow(1.2, tier - 1)
	projectile_rate  = maxf(projectile_rate * pow(0.85, tier - 1), 0.8)
	death_spit_count = death_spit_count + (tier - 1)
#endregion
