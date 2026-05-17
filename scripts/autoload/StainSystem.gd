extends Node

const MAX_STAINS: int = 20

var active_stains: Array = []
var _tilemap: TileMapLayer = null

func get_filth_percent() -> float:
	return float(active_stains.size()) / MAX_STAINS * 100.0

func register_tilemap(layer: TileMapLayer) -> void:
	_tilemap = layer

func can_spawn_stain(spawn_position: Vector2, surface_normal: Vector2 = Vector2.ZERO, stain_radius: float = 16.0) -> bool:
	if active_stains.size() >= MAX_STAINS:
		return false
	var sample_pos := spawn_position - surface_normal * 4.0
	if not _is_stainable_at(sample_pos):
		return false
	for stain in active_stains:
		if stain.global_position.distance_to(spawn_position) < stain_radius * 1.3:
			return false
	return true

func _is_stainable_at(global_pos: Vector2) -> bool:
	if _tilemap == null:
		return true
	var coords := _tilemap.local_to_map(_tilemap.to_local(global_pos))
	var td := _tilemap.get_cell_tile_data(coords)
	return td != null and td.get_custom_data("stainable")

func register_stain(stain: Node) -> void:
	active_stains.append(stain)

func unregister_stain(stain: Node) -> void:
	active_stains.erase(stain)
