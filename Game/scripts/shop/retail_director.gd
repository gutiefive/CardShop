class_name RetailDirector
extends Node3D
@export var hud_path: NodePath
@export var shelf_paths: Array[NodePath] = []
@export var entry_path: NodePath
@export var junction_path: NodePath
@export var aisle_path: NodePath
@export var queue_front_path: NodePath
@export var spawn_interval: float = 7.0
@export var max_customers: int = 3
var model := RetailSession.new(preload("res://data/rookie_pack.tres"),preload("res://data/rookie_box.tres"))
var shelves: Array[ShelfStockInteractable] = []
var customers: Array[ShopCustomer] = []
var queue: Array[ShopCustomer] = []
var shop_open: bool = false
var spawn_remaining: float = 1.0
var next_customer_id: int = 1
var next_shelf: int = 0

func _ready() -> void:
	# Sibling shelves must finish their onready reference wiring first.
	call_deferred("initialize_shelves")

func initialize_shelves() -> void:
	for path in shelf_paths:
		var shelf: ShelfStockInteractable = get_node(path)
		shelves.append(shelf)
		var registered := model.register_shelf(shelf.shelf_id,shelf.product,shelf.visual_paths.size())
		assert(registered,"Duplicate or invalid authored retail shelf")
	refresh_shelves()

func set_open(value: bool) -> void:
	shop_open = value
	spawn_remaining = 1.0

func _process(delta: float) -> void:
	if not shop_open:
		return
	spawn_remaining -= delta
	if spawn_remaining <= 0:
		spawn_customer()
		spawn_remaining = spawn_interval

func refresh_shelves() -> void:
	for shelf in shelves:
		shelf.refresh()

func point(path: NodePath) -> Vector3:
	return get_node(path).global_position

func spawn_customer() -> ShopCustomer:
	if not shop_open or customers.size() >= max_customers:
		return null
	var shelf: ShelfStockInteractable
	for offset in range(shelves.size()):
		var index := (next_shelf+offset)%shelves.size()
		if model.shelf_count(shelves[index].shelf_id) > 0:
			shelf = shelves[index]
			next_shelf = (index+1)%shelves.size()
			break
	if not shelf:
		return null
	var customer := ShopCustomer.new()
	customer.name = "Customer%d" % next_customer_id
	customer.customer_id = next_customer_id
	next_customer_id += 1
	customer.retail = self
	customer.shelf = shelf
	customer.collision_layer = 8
	customer.collision_mask = 1 | 4
	var mesh := MeshInstance3D.new()
	mesh.mesh = CapsuleMesh.new()
	mesh.mesh.radius = 0.25
	mesh.mesh.height = 1.7
	mesh.material_override = ShopBuilder.material(Color.from_hsv(fmod(customer.customer_id*0.23,1.0),0.55,0.8))
	mesh.position.y = 0.85
	customer.add_child(mesh)
	var collider := CollisionShape3D.new()
	collider.shape = CapsuleShape3D.new()
	collider.shape.radius = 0.25
	collider.shape.height = 1.7
	collider.position.y = 0.85
	customer.add_child(collider)
	var label := Label3D.new()
	label.position.y = 2.0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	label.pixel_size = 0.004
	customer.add_child(label)
	customer.status_label = label
	add_child(customer)
	customer.global_position = point(entry_path)+Vector3(0,0.05,0)
	customers.append(customer)
	customer.walk([point(junction_path),point(aisle_path),shelf.browse_position()],ShopCustomer.State.TO_SHELF)
	return customer

func finish_browsing(customer: ShopCustomer) -> void:
	if model.reserve(customer.customer_id,customer.shelf.shelf_id):
		queue.append(customer)
		customer.walk([point(aisle_path),point(junction_path),queue_position(queue.size()-1)],ShopCustomer.State.TO_QUEUE)
		refresh_shelves()
	else:
		leave(customer,true)

func queue_position(index: int) -> Vector3:
	return point(queue_front_path)+Vector3(0,0,index*0.9)

func checkout_prompt() -> String:
	if queue.is_empty():
		return "Checkout · No customers waiting"
	var front := queue[0]
	if front.state != ShopCustomer.State.WAITING:
		return "Checkout · Customer approaching"
	return "E · Sell %s · %s (%d waiting)" % [model.order_name(front.customer_id),ProductDefinition.format_price(model.order_price(front.customer_id)),queue.size()]

func serve_next() -> int:
	if queue.is_empty() or queue[0].state != ShopCustomer.State.WAITING:
		return 0
	var customer: ShopCustomer = queue.pop_front()
	var price := model.complete_sale(customer.customer_id)
	leave(customer,false)
	for i in range(queue.size()):
		# Keep approaching customers on their aisle route; only waiting customers move directly.
		if queue[i].state == ShopCustomer.State.WAITING:
			queue[i].walk([queue_position(i)],ShopCustomer.State.TO_QUEUE)
		elif not queue[i].route.is_empty():
			queue[i].route[-1] = queue_position(i)
	return price

func leave(customer: ShopCustomer, from_shelf: bool) -> void:
	var points: Array[Vector3] = []
	if from_shelf:
		points.append(point(aisle_path))
	points.append(point(junction_path))
	points.append(point(entry_path))
	customer.walk(points,ShopCustomer.State.LEAVING)

func customer_left(customer: ShopCustomer) -> void:
	model.cancel_order(customer.customer_id)
	customers.erase(customer)
	refresh_shelves()
	customer.queue_free()
