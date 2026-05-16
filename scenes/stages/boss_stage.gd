extends Node2D

const BACTERIA_SCENE = preload("res://scenes/boss/BacteriaTier1.tscn")

enum Phase { DEFEND, CLEAN }

const CLEAN_PHASE_MIN := 5.0
const CLEAN_PHASE_MAX := 10.0

var current_phase: Phase = Phase.DEFEND
var _clean_timer: float = 0.0

var _current_tier: int = 1

@export var bacteria_spawn_position: Vector2 = Vector2(300, -50)

@onready var _clean_time_label: Label = $CanvasLayer/CleanTime

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
	var bacteria := BACTERIA_SCENE.instantiate() as BacteriaTier1
	bacteria.global_position = bacteria_spawn_position
	bacteria.apply_tier(_current_tier)
	add_child(bacteria)
	bacteria.defeated.connect(on_bacteria_defeated)

func _start_clean_phase() -> void:
	current_phase = Phase.CLEAN
	_clean_timer = randf_range(CLEAN_PHASE_MIN, CLEAN_PHASE_MAX)
	_clean_time_label.show()
	# TODO: notify player Clean Phase has started (UI pulse, audio cue, etc.)

func _end_clean_phase() -> void:
	if StainSystem.get_filth_percent() == 0.0:
		_win()
	else:
		_current_tier += 1
		_start_defend_phase()

func _win() -> void:
	pass  # TODO: win condition
