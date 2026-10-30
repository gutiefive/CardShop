class_name CheckoutInteractable
extends Interactable
@export var retail_path: NodePath
@export var label_path: NodePath
@onready var retail: RetailDirector = get_node(retail_path)

func prompt() -> String:
	return retail.checkout_prompt()

func interact(hud: ShopHUD) -> void:
	var price := retail.serve_next()
	hud.notify("Sale complete: " + ProductDefinition.format_price(price) if price > 0 else "No customer ready at checkout")

func _process(_delta: float) -> void:
	get_node(label_path).text = "CHECKOUT\n%d waiting · %d sold" % [retail.queue.size(),retail.model.sales_count]
