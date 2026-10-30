class_name ShopSign
extends Interactable

@export var label_path: NodePath
var is_open: bool = false

func prompt() -> String:
	return "E · Set shop " + ("closed" if is_open else "open")

func interact(hud: ShopHUD) -> void:
	is_open = not is_open
	get_node(label_path).text = "OPEN" if is_open else "CLOSED"
	hud.notify("Shop sign: " + ("OPEN" if is_open else "CLOSED"))
