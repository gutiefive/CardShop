class_name RetailSession
extends RefCounted
## Authoritative shop economy. Scene/customer code never edits stock directly.
signal changed
const BACKROOM_UPGRADE_CENTS := 10000
var revenue_cents: int = 0
var expenses_cents: int = 0
var backroom_expanded: bool = false
var _products: Dictionary = {}
var cash_cents: int = 50000
var sales_count: int = 0
var _backroom: Dictionary = {}
var _shelves: Dictionary = {}
var _orders: Dictionary = {}

func _init(pack: ProductDefinition = null, box: ProductDefinition = null) -> void:
	if pack:
		_backroom[pack.stable_id] = 12
		_products[pack.stable_id] = pack
	if box:
		_backroom[box.stable_id] = 3
		_products[box.stable_id] = box

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
	if moved > 0:
		changed.emit()
	return moved

func reserve(customer_id: int, shelf_id: String) -> bool:
	if customer_id < 1 or _orders.has(customer_id) or shelf_count(shelf_id) < 1:
		return false
	var shelf: Dictionary = _shelves[shelf_id]
	var product: ProductDefinition = shelf.product
	shelf.stock -= 1
	_orders[customer_id] = {"shelf_id":shelf_id,"product_id":product.stable_id,"name":product.display_name,"price":product.retail_cents}
	changed.emit()
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
	revenue_cents += price
	sales_count += 1
	_orders.erase(customer_id)
	changed.emit()
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
	changed.emit()
	return true

func level() -> int:
	return 3 if sales_count >= 15 else 2 if sales_count >= 5 else 1

func level_name() -> String:
	return ["Neighborhood Shop","Local Favorite","Card Destination"][level()-1]

func next_level_sales() -> int:
	return 5 if level() == 1 else 15 if level() == 2 else 0

func backroom_capacity(product_id: String) -> int:
	if not _products.has(product_id):
		return 0
	var product: ProductDefinition = _products[product_id]
	var base := 24 if product.product_type == ProductDefinition.ProductType.BOOSTER_PACK else 6
	return base * (2 if backroom_expanded else 1)

func can_order_stock(product_id: String, quantity: int) -> bool:
	if not _products.has(product_id) or quantity < 1 or quantity > 99:
		return false
	var product: ProductDefinition = _products[product_id]
	return product.purchase_cents > 0 and cash_cents >= product.purchase_cents*quantity and backroom_count(product_id)+quantity <= backroom_capacity(product_id)

func order_stock(product_id: String, quantity: int) -> int:
	if not can_order_stock(product_id,quantity):
		return 0
	var cost: int = _products[product_id].purchase_cents*quantity
	cash_cents -= cost
	expenses_cents += cost
	_backroom[product_id] = backroom_count(product_id)+quantity
	changed.emit()
	return cost

func consume_backroom(product_id: String) -> bool:
	if backroom_count(product_id) < 1:
		return false
	_backroom[product_id] = backroom_count(product_id)-1
	changed.emit()
	return true

func can_upgrade_backroom() -> bool:
	return level() >= 2 and not backroom_expanded and cash_cents >= BACKROOM_UPGRADE_CENTS

func upgrade_backroom() -> bool:
	if not can_upgrade_backroom():
		return false
	backroom_expanded = true
	cash_cents -= BACKROOM_UPGRADE_CENTS
	expenses_cents += BACKROOM_UPGRADE_CENTS
	changed.emit()
	return true

func snapshot() -> Dictionary:
	var stock: Dictionary = {}
	var backroom := _backroom.duplicate()
	for id in _shelves:
		stock[id] = int(_shelves[id].stock)
	# Customers are transient. Fold their held units into this checkpoint only.
	for order in _orders.values():
		var shelf: Dictionary = _shelves[order.shelf_id]
		if stock[order.shelf_id] < int(shelf.capacity):
			stock[order.shelf_id] += 1
		else:
			backroom[order.product_id] = int(backroom[order.product_id])+1
	return {"cash":cash_cents,"sales":sales_count,"revenue":revenue_cents,"expenses":expenses_cents,"expanded":backroom_expanded,"backroom":backroom,"shelves":stock}

func snapshot_errors(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not data is Dictionary:
		return PackedStringArray(["Retail save must be an object"])
	for field in ["cash","sales","revenue","expenses"]:
		if not SaveValues.whole(data.get(field)):
			errors.append("Invalid retail number: " + field)
	if not data.get("expanded") is bool:
		errors.append("Invalid upgrade flag")
	if not errors.is_empty():
		return errors
	if int(data.cash) != 50000+int(data.revenue)-int(data.expenses):
		errors.append("Cash does not match revenue/expenses ledger")
	if data.expanded and (int(data.sales) < 5 or int(data.expenses) < BACKROOM_UPGRADE_CENTS):
		errors.append("Invalid backroom upgrade progression")
	for field in ["backroom","shelves"]:
		var known: Dictionary = _products if field == "backroom" else _shelves
		var counts: Variant = data.get(field)
		if not counts is Dictionary or counts.size() != known.size():
			errors.append("Missing or unknown inventory entries: " + field)
			continue
		for id in known:
			var maximum: int = 1000000 if field == "backroom" else int(_shelves[id].capacity)
			if not SaveValues.whole(counts.get(id),0,maximum):
				errors.append("Invalid inventory count: " + str(id))
	return errors

func restore_snapshot(data: Dictionary) -> bool:
	if not snapshot_errors(data).is_empty():
		return false
	cash_cents = int(data.cash)
	sales_count = int(data.sales)
	revenue_cents = int(data.revenue)
	expenses_cents = int(data.expenses)
	backroom_expanded = data.expanded
	for id in _products:
		_backroom[id] = int(data.backroom[id])
	for id in _shelves:
		_shelves[id].stock = int(data.shelves[id])
	_orders.clear()
	return true
