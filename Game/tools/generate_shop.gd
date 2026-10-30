extends SceneTree

func _initialize() -> void:
	var error := ShopBuilder.save_scene()
	if error != OK:
		push_error("Shop generation failed: " + error_string(error))
		quit(1)
	else:
		print("Generated " + ShopBuilder.SCENE_PATH)
		quit(0)
