extends Label

func _process(_delta: float) -> void:
	text = "%d%%" % int(StainSystem.get_filth_percent())
