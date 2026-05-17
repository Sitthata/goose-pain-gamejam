extends Node2D

const BACTERIA_SCENE = preload("res://scenes/boss/BacteriaTier1.tscn")

enum Phase { DEFEND, CLEAN }

# Difficulty tiers keyed by tier number.
# To add a new moveset: add one key to each dict here.
const TIER_STATS := {
	1: {tier=1, lunge=false, spit_cd=5.0, death_spits=2, lunge_cd=8.0, lunge_dur=0.2, lunge_stains=2, dodge=0.0},
	2: {tier=2, lunge=true,  spit_cd=3.0, death_spits=3, lunge_cd=6.0, lunge_dur=0.3, lunge_stains=3, dodge=0.3},
	3: {tier=3, lunge=true,  spit_cd=3.0, death_spits=4, lunge_cd=5.0, lunge_dur=0.4, lunge_stains=3, dodge=0.5},
}

func _filth_to_tier(filth: float) -> int:
	if filth < 20.0: return 1
	if filth < 30.0: return 2
	return 3

const CLEAN_PHASE_MIN := 5.0
const CLEAN_PHASE_MAX := 10.0

var current_phase: Phase = Phase.DEFEND
var _clean_timer: float = 0.0

@export var bacteria_spawn_position: Vector2 = Vector2(300, -50)

@onready var _clean_time_label: Label = $CanvasLayer/CleanTime
@onready var _player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	_start_defend_phase()

func _process(delta: float) -> void:
	if current_phase == Phase.CLEAN:
		_clean_timer -= delta
		_clean_time_label.text = "Clean Phase: %d seconds" % ceili(_clean_timer)
		if _clean_timer <= 0.0:
			_end_clean_phase()

# Called when the Bacteria emits the defeated signal
func on_bacteria_defeated() -> void:
	_start_clean_phase()

func _start_defend_phase() -> void:
	current_phase = Phase.DEFEND
	_clean_time_label.hide()
	_player.set_cleaning_enabled(false)
	var bacteria := BACTERIA_SCENE.instantiate() as BacteriaTier1
	bacteria.global_position = bacteria_spawn_position
	var tier := _filth_to_tier(StainSystem.get_filth_percent())
	bacteria.apply_stats(TIER_STATS[tier])
	add_child(bacteria)
	bacteria.defeated.connect(on_bacteria_defeated)

func _start_clean_phase() -> void:
	current_phase = Phase.CLEAN
	_clean_timer = randf_range(CLEAN_PHASE_MIN, CLEAN_PHASE_MAX)
	_clean_time_label.show()
	_player.set_cleaning_enabled(true)
	# TODO: notify player Clean Phase has started (UI pulse, audio cue, etc.)

func _end_clean_phase() -> void:
	if StainSystem.get_filth_percent() == 0.0:
		_win()
	else:
		_start_defend_phase()

func _win() -> void:
	pass  # TODO: win condition
