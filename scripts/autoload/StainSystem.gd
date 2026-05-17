extends Node

const MAX_STAINS: int = 20

var active_stains: Array = []

func get_filth_percent() -> float:
	return float(active_stains.size()) / MAX_STAINS * 100.0

func can_spawn_stain(spawn_position: Vector2, stain_radius: float = 16.0) -> bool:
	if active_stains.size() >= MAX_STAINS:
		return false
	for stain in active_stains:
		if stain.global_position.distance_to(spawn_position) < stain_radius * 1.3:
			return false
	return true

func register_stain(stain: Node) -> void:
	active_stains.append(stain)

func unregister_stain(stain: Node) -> void:
	active_stains.erase(stain)
