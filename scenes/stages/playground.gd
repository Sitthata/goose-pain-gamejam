extends Node2D

## Dev playground — no game loop, no phases.
## Hotkeys:
##   1-9 = spawn bacteria tier 1-9
##   0   = spawn bacteria tier 10
##   R   = clear all stains
##   F   = print current filth % to output
##
## Note: If a BacteriaTier1 node exists in the scene it will be freed on _ready.
##       This script manages bacteria spawning entirely via _spawn_bacteria().

const BACTERIA_SCENE = preload("res://scenes/boss/BacteriaTier1.tscn")

@export var bacteria_spawn_position: Vector2 = Vector2(521, 464)

@onready var _tilemap: TileMapLayer = $TileMapLayer

var _bacteria: BacteriaTier1 = null
var _current_tier: int = 1
var _debug_label: Label
var _tier_label: Label


func _ready() -> void:
	StainSystem.register_tilemap(_tilemap)
	_spawn_debug_ui()

	# Free any pre-placed BacteriaTier1 from the scene — capture its position first
	var existing := get_node_or_null("BacteriaTier1") as BacteriaTier1
	if is_instance_valid(existing):
		bacteria_spawn_position = existing.position
		existing.queue_free()

	_spawn_bacteria(1)

	var room_center := get_tree().get_first_node_in_group("room_center")
	if not is_instance_valid(room_center):
		push_warning("Playground: no Marker2D in group 'room_center' — add one for correct JUMP direction")


func _process(_delta: float) -> void:
	_debug_label.text = "Filth: %.0f%%  Stains: %d / %d" % [
		StainSystem.get_filth_percent(),
		StainSystem.active_stains.size(),
		StainSystem.MAX_STAINS,
	]


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_R: _clear_stains()
		KEY_F: print("Filth: %.1f%%" % StainSystem.get_filth_percent())
		KEY_1: _spawn_bacteria(1)
		KEY_2: _spawn_bacteria(2)
		KEY_3: _spawn_bacteria(3)
		KEY_4: _spawn_bacteria(4)
		KEY_5: _spawn_bacteria(5)
		KEY_6: _spawn_bacteria(6)
		KEY_7: _spawn_bacteria(7)
		KEY_8: _spawn_bacteria(8)
		KEY_9: _spawn_bacteria(9)
		KEY_0: _spawn_bacteria(10)


## Spawn bacteria at the given stat tier (1–10).
## Kills any existing bacteria first. Stats come from BacteriaStats.for_filth().
func _spawn_bacteria(tier: int) -> void:
	if is_instance_valid(_bacteria):
		_bacteria.queue_free()

	_current_tier = tier
	var filth_midpoint := (tier - 1) * 10.0 + 5.0
	var stats := BacteriaStats.for_filth(filth_midpoint)

	_bacteria = BACTERIA_SCENE.instantiate() as BacteriaTier1
	_bacteria.position = bacteria_spawn_position
	add_child(_bacteria)
	_bacteria.apply_stats(stats)
	_bacteria.defeated.connect(_on_bacteria_defeated)

	_tier_label.text = "Tier: %d  (1-9, 0=tier10)" % tier


func _on_bacteria_defeated() -> void:
	await get_tree().create_timer(2.0).timeout
	_spawn_bacteria(_current_tier)


func _clear_stains() -> void:
	for stain in StainSystem.active_stains.duplicate():
		stain.queue_free()
	StainSystem.active_stains.clear()
	print("Playground: stains cleared")


func _spawn_debug_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	_debug_label = Label.new()
	_debug_label.position = Vector2(8, 8)
	canvas.add_child(_debug_label)

	_tier_label = Label.new()
	_tier_label.position = Vector2(8, 32)
	canvas.add_child(_tier_label)

	var hint := Label.new()
	hint.position = Vector2(8, 56)
	hint.text = "R = clear stains  |  1-9, 0=tier10 = spawn tier  |  F = print filth"
	canvas.add_child(hint)
