extends Node2D

const BACTERIA_SCENE = preload("res://scenes/boss/BacteriaTier1.tscn")
@onready var tier_label: Label = $CanvasLayer/BacteriaTier

enum Phase { DEFEND, CLEAN }

# Difficulty tiers keyed by tier number.
# To add a new moveset: add one key to each dict here.
# tier, lunge, spit_cd, death_spits, lunge_cd, lunge_dur, lunge_stains, dodge, jump_enabled, slam_enabled, slam_cd
func _stats_for_filth(filth: float) -> BacteriaStats:
	if filth < 10.0: return BacteriaStats.new(1, false, 5.0, 2, 8.0, 0.2, 2, 0.0, false, false, 14.0)
	if filth < 25.0: return BacteriaStats.new(2, true,  3.0, 3, 6.0, 0.3, 3, 0.3, true,  true,  12.0)
	return             BacteriaStats.new(3, true,  3.0, 4, 5.0, 0.4, 3, 0.5, true,  true,  10.0)

const CLEAN_PHASE_MIN := 5.0
const CLEAN_PHASE_MAX := 8.0

var current_phase: Phase = Phase.DEFEND
var _clean_timer: float = 0.0

@export var bacteria_spawn_position: Vector2 = Vector2(300, -50)

@onready var _clean_time_label: Label = $CanvasLayer/CleanTime
@onready var _player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	StainSystem.register_tilemap($TileMapLayer)
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
	var stats := _stats_for_filth(StainSystem.get_filth_percent())
	bacteria.apply_stats(stats)
	add_child(bacteria)
	bacteria.global_position = $BacteriaSpawnPosition.position
	bacteria.defeated.connect(on_bacteria_defeated)

	# Debug
	tier_label.text = str("Tier: ", stats.tier)

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
	current_phase = Phase.DEFEND  # stop the clean timer loop
	_clean_time_label.hide()
	# TODO: win condition (show win screen, etc.)
