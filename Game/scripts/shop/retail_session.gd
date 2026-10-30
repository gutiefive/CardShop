class_name RetailSession
extends RefCounted
## Authoritative session stock and sales. Scene/customer code never edits counts directly.
var cash_cents: int = 50000
var sales_count: int = 0
var _backroom: Dictionary = {}
var _shelves: Dictionary = {}
var _orders: Dictionary = {}

func _init(pack: ProductDefinition = null, box: ProductDefinition = null) -> void:
	if pack:
		_backroom[pack.stable_id] = 12
	if box:
		_backroom[box.stable_id] = 3

func register_shelf(id: String, product: ProductDefinition, capacity: int) -> bool:
	if id.is_empty() or _shelves.has(id) or not product or not product.validation_errors().is_empty() or capacity < 1:
		return false
	_shelves[id] = {"product":product,"capacity":capacity,"stock":0}
	return true

func backroom_count(product_id: String) -> int:
	return _backroom.get(product_id,0)

func shelf_count(id: String) -> int:
	return int(_shelves[id].stock) if _shelves.has(id) else 0

func stock_shelf(id: String) -> int:
	if not _shelves.has(id):
		return 0
	var shelf: Dictionary = _shelves[id]
	var product: ProductDefinition = shelf.product
	var moved := mini(int(shelf.capacity)-int(shelf.stock),backroom_count(product.stable_id))
	shelf.stock += moved
	_backroom[product.stable_id] = backroom_count(product.stable_id)-moved
	return moved

func reserve(customer_id: int, shelf_id: String) -> bool:
	if customer_id < 1 or _orders.has(customer_id) or shelf_count(shelf_id) < 1:
		return false
	var shelf: Dictionary = _shelves[shelf_id]
	var product: ProductDefinition = shelf.product
	shelf.stock -= 1
	_orders[customer_id] = {"shelf_id":shelf_id,"product_id":product.stable_id,"name":product.display_name,"price":product.retail_cents}
	return true

func order_name(customer_id: int) -> String:
	return str(_orders[customer_id].name) if _orders.has(customer_id) else ""

func order_price(customer_id: int) -> int:
	return int(_orders[customer_id].price) if _orders.has(customer_id) else 0

func has_order(customer_id: int) -> bool:
	return _orders.has(customer_id)

func complete_sale(customer_id: int) -> int:
	if not _orders.has(customer_id):
		return 0
	var price := order_price(customer_id)
	cash_cents += price
	sales_count += 1
	_orders.erase(customer_id)
	return price

func cancel_order(customer_id: int) -> bool:
	if not _orders.has(customer_id):
		return false
	var order: Dictionary = _orders[customer_id]
	var shelf: Dictionary = _shelves[order.shelf_id]
	if int(shelf.stock) < int(shelf.capacity):
		shelf.stock += 1
	else:
		_backroom[order.product_id] = backroom_count(order.product_id)+1
	_orders.erase(customer_id)
	return true
