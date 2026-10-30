class_name Interactable
extends StaticBody3D
## Common interaction contract; subclasses provide behavior only.
func prompt() -> String:
	return "E · Interact"

func interact(_hud: ShopHUD) -> void:
	pass
