extends Area2D

# How far along the Clean Action is for this specific stain (0.0 = untouched, 1.0 = done)
var cleaning_progress: float = 0.0

func _ready() -> void:
	add_to_group("stain")
	StainSystem.register_stain(self)

func advance_clean(amount: float) -> void:
	cleaning_progress = minf(cleaning_progress + amount, 1.0)
	if cleaning_progress >= 1.0:
		_remove()

func reset_clean() -> void:
	cleaning_progress = 0.0

func _remove() -> void:
	StainSystem.unregister_stain(self)
	queue_free()
