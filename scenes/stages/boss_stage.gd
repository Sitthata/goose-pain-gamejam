extends Node2D

enum Phase { DEFEND, CLEAN }

const CLEAN_PHASE_MIN := 5.0
const CLEAN_PHASE_MAX := 10.0

var current_phase: Phase = Phase.DEFEND
var _clean_timer: float = 0.0

func _ready() -> void:
	_start_defend_phase()

func _process(delta: float) -> void:
	if current_phase == Phase.CLEAN:
		_clean_timer -= delta
		if _clean_timer <= 0.0:
			_end_clean_phase()

# Called when the Bacteria is defeated
func on_bacteria_defeated() -> void:
	_start_clean_phase()

func _start_defend_phase() -> void:
	current_phase = Phase.DEFEND
	# TODO: spawn Bacteria

func _start_clean_phase() -> void:
	current_phase = Phase.CLEAN
	_clean_timer = randf_range(CLEAN_PHASE_MIN, CLEAN_PHASE_MAX)
	# TODO: notify player Clean Phase has started

func _end_clean_phase() -> void:
	if StainSystem.get_filth_percent() == 0.0:
		_win()
	else:
		_start_defend_phase()
		# TODO: spawn next Bacteria tier

func _win() -> void:
	pass  # TODO: win condition
