extends Node2D

## Dev playground — no game loop, no phases.
## Bacteria spawns with configurable stats and respawns on death.
## Hotkeys:
##   R — clear all stains
##   T — cycle test tier (1 / 2 / 3)
##   F — print current filth % to output

@export var test_tier: int = 1  # starting tier; cycle with T

@onready var _bacteria: BacteriaTier1 = $BacteriaTier1
@onready var _tilemap: TileMapLayer = $TileMapLayer

var _debug_label: Label
var _tier_label: Label


func _ready() -> void:
	StainSystem.register_tilemap(_tilemap)
	_spawn_debug_ui()
	_apply_tier(test_tier)
	_bacteria.defeated.connect(_on_bacteria_defeated)

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
		KEY_R:
			_clear_stains()
		KEY_T:
			test_tier = (test_tier % 3) + 1
			_apply_tier(test_tier)
		KEY_F:
			print("Filth: %.1f%%" % StainSystem.get_filth_percent())


func _apply_tier(tier: int) -> void:
	# tier, lunge, spit_cd, death_spits, lunge_cd, lunge_dur, lunge_stains, dodge, jump_enabled, slam_enabled, slam_cd
	var stats: BacteriaStats
	match tier:
		1: stats = BacteriaStats.new(1, false, 5.0, 2, 8.0, 0.2, 2, 0.0, false, false, 14.0)
		2: stats = BacteriaStats.new(2, true,  3.0, 3, 6.0, 0.3, 3, 0.3, true,  true,  12.0)
		3: stats = BacteriaStats.new(3, true,  3.0, 4, 5.0, 0.4, 3, 0.5, true,  true,  10.0)
		_: stats = BacteriaStats.new(1, false, 5.0, 2, 8.0, 0.2, 2, 0.0, false, false, 14.0)
	_bacteria.apply_stats(stats)
	_tier_label.text = "Tier: %d  (T to cycle)" % tier


func _on_bacteria_defeated() -> void:
	# Respawn bacteria at its original position after a short delay
	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(_bacteria):
		# Bacteria was queue_freed — re-instance from scratch
		var scene := load("res://scenes/boss/BacteriaTier1.tscn") as PackedScene
		_bacteria = scene.instantiate() as BacteriaTier1
		_bacteria.position = Vector2(521, 464)
		add_child(_bacteria)
	_apply_tier(test_tier)
	_bacteria.defeated.connect(_on_bacteria_defeated)


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
	hint.text = "R = clear stains  |  T = cycle tier  |  F = print filth"
	canvas.add_child(hint)
