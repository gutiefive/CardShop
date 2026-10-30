class_name ProductInteractable
extends Interactable

@export var product: ProductDefinition

func prompt() -> String:
	return "E · Inspect " + product.display_name if product else ""

func interact(hud: ShopHUD) -> void:
	if product:
		hud.inspect_product(product)
