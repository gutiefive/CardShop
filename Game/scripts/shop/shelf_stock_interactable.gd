class_name ShelfStockInteractable
extends Interactable
@export var shelf_id: String
@export var product: ProductDefinition
@export var retail_path: NodePath
@export var label_path: NodePath
@export var browse_path: NodePath
@export var visual_paths: Array[NodePath] = []
@onready var retail: RetailDirector = get_node(retail_path)

func prompt() -> String:
	return "E · Stock %s · Shelf %d/%d · Backroom %d" % [product.display_name,retail.model.shelf_count(shelf_id),visual_paths.size(),retail.model.backroom_count(product.stable_id)]

func interact(hud: ShopHUD) -> void:
	var moved := retail.model.stock_shelf(shelf_id)
	retail.refresh_shelves()
	hud.notify("Stocked %d × %s" % [moved,product.display_name] if moved else "Shelf full or backroom empty")

func refresh() -> void:
	var count := retail.model.shelf_count(shelf_id)
	get_node(label_path).text = "%s\n%d / %d · E to stock" % [product.display_name,count,visual_paths.size()]
	for i in range(visual_paths.size()):
		var body: ProductInteractable = get_node(visual_paths[i])
		body.visible = i < count
		body.collision_layer = 1 if i < count else 0

func browse_position() -> Vector3:
	return get_node(browse_path).global_position
