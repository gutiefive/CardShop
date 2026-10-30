class_name RetailTests
extends RefCounted

static func run(check: Callable) -> void:
	var pack: ProductDefinition = load("res://data/rookie_pack.tres")
	var box: ProductDefinition = load("res://data/rookie_box.tres")
	var model := RetailSession.new(pack,box)
	check.call(model.cash_cents == 50000 and model.backroom_count(pack.stable_id) == 12 and model.backroom_count(box.stable_id) == 3,"M4 starts with $500 and finite backroom inventory")
	check.call(model.register_shelf("pack",pack,9),"Retail shelf registers")
	check.call(not model.register_shelf("pack",box,9),"Duplicate shelf ID rejected")
	check.call(not model.register_shelf("bad",null,9) and not model.register_shelf("bad",pack,0),"Invalid shelf definition/capacity rejected")
	check.call(model.shelf_count("pack") == 0,"Shelf starts empty")
	check.call(model.stock_shelf("pack") == 9 and model.backroom_count(pack.stable_id) == 3,"Stock transfer respects shelf capacity and debits backroom")
	check.call(model.stock_shelf("pack") == 0 and model.stock_shelf("missing") == 0,"Full or unknown shelf cannot create stock")
	check.call(not model.reserve(0,"pack") and not model.reserve(1,"missing"),"Invalid reservation cannot take stock")
	check.call(model.reserve(1,"pack") and model.shelf_count("pack") == 8,"Customer pickup reserves exactly one shelf unit")
	check.call(not model.reserve(1,"pack") and model.shelf_count("pack") == 8,"Same customer cannot reserve twice")
	check.call(model.order_price(1) == 400 and model.cash_cents == 50000,"Pickup locks retail price without crediting cash")
	check.call(model.complete_sale(1) == 400 and model.cash_cents == 50400 and model.sales_count == 1,"Checkout credits one exact retail sale")
	check.call(model.complete_sale(1) == 0 and model.cash_cents == 50400,"Repeated checkout cannot duplicate revenue")
	model.reserve(2,"pack")
	check.call(model.cancel_order(2) and model.shelf_count("pack") == 8,"Cancelled basket returns its unit to shelf")
	check.call(not model.cancel_order(2),"Cancelled basket cannot return stock twice")
	model.reserve(3,"pack")
	model.stock_shelf("pack")
	var backroom_before := model.backroom_count(pack.stable_id)
	check.call(model.cancel_order(3) and model.shelf_count("pack") == 9 and model.backroom_count(pack.stable_id) == backroom_before+1,"Cancellation returns to backroom when shelf refilled")
	check.call(model.register_shelf("box",box,9) and model.stock_shelf("box") == 3,"Backroom limits hobby-box stocking")
	model.reserve(4,"box")
	check.call(model.complete_sale(4) == 6500 and model.cash_cents == 56900,"Hobby-box checkout uses its own price")
	check.call(pack.retail_cents == 400 and box.retail_cents == 6500,"Retail transactions preserve authored prices")

static func frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame

static func wait_for_queue(tree: SceneTree, retail: RetailDirector, count: int) -> bool:
	for i in range(1800):
		if retail.queue.size() == count:
			var ready := true
			for customer in retail.queue:
				ready = ready and customer.state == ShopCustomer.State.WAITING
			if ready:
				return true
		await tree.physics_frame
	return false

static func run_scene(tree: SceneTree, check: Callable) -> void:
	var packed: PackedScene = load(ShopBuilder.SCENE_PATH)
	var shop := packed.instantiate()
	tree.root.add_child(shop)
	await frames(tree,4)
	# Explicit authored references, not name searches, drive the same runtime loop.
	var hud: ShopHUD
	var player: FirstPersonPlayer
	for child in shop.get_children():
		if child is ShopHUD:
			hud = child
		elif child is FirstPersonPlayer:
			player = child
	var retail := hud.retail
	retail.set_process(false) # Control admission deterministically, while real customer physics runs.
	check.call(retail.shelves.size() == 3,"Packed scene wires three retail shelves")
	check.call(retail.spawn_customer() == null,"Closed shop admits no customers")
	retail.set_open(true)
	check.call(retail.spawn_customer() == null,"Unstocked shop does not admit a buyer")
	player.position = Vector3(-4,0.05,-3)
	player.camera.look_at(retail.shelves[0].global_position)
	var interact := InputEventAction.new()
	interact.action = "interact"
	interact.pressed = true
	player._unhandled_input(interact)
	check.call(retail.model.shelf_count(retail.shelves[0].shelf_id) == 9,"Camera ray and E can stock the shelf board")
	for shelf in retail.shelves:
		shelf.interact(hud)
	check.call(retail.model.shelf_count(retail.shelves[0].shelf_id) == 9 and retail.model.shelf_count(retail.shelves[1].shelf_id) == 3 and retail.model.shelf_count(retail.shelves[2].shelf_id) == 3,"E-stock interactions move all finite backroom stock to shelves")
	var first_visual: ProductInteractable = retail.shelves[0].get_node(retail.shelves[0].visual_paths[0])
	check.call(first_visual.visible and first_visual.collision_layer == 1,"Stocked shelf products become visible and inspectable")
	var buyer := retail.spawn_customer()
	var second := retail.spawn_customer()
	var third := retail.spawn_customer()
	check.call(buyer != null and second != null and third != null and retail.spawn_customer() == null,"Customer admission respects the three-customer cap")
	check.call(retail.serve_next() == 0 and retail.model.cash_cents == 50000,"Checkout cannot sell before a buyer arrives")
	await frames(tree,10)
	var before := buyer.global_position
	var pause := InputEventAction.new()
	pause.action = "pause"
	pause.pressed = true
	hud._unhandled_input(pause)
	await frames(tree,5)
	check.call(buyer.global_position.is_equal_approx(before) and tree.paused,"Pause suspends retail customer movement")
	hud.resume()
	var queued := await wait_for_queue(tree,retail,3)
	check.call(queued,"Customers physically walk all three shelf routes, browse, reserve and queue")
	if not queued:
		for customer in retail.customers:
			print("CUSTOMER DEBUG ",customer.customer_id," state=",customer.state," position=",customer.global_position," route=",customer.route)
		shop.queue_free()
		await tree.process_frame
		return
	check.call(retail.model.shelf_count(retail.shelves[0].shelf_id) == 8 and retail.model.shelf_count(retail.shelves[1].shelf_id) == 2 and retail.model.shelf_count(retail.shelves[2].shelf_id) == 2,"Three buyers remove one item from their respective shelves")
	retail.set_open(false)
	check.call(retail.spawn_customer() == null and retail.queue.size() == 3,"Closing stops admission while retaining waiting orders")
	var front_id := retail.queue[0].customer_id
	var expected := retail.model.order_price(front_id)
	var register: CheckoutInteractable
	for child in shop.get_children():
		if child is CheckoutInteractable:
			register = child
	player.position = Vector3(3,0.05,0)
	player.camera.look_at(register.global_position)
	player._unhandled_input(interact)
	check.call(hud.notice_label.text.contains("Sale complete"),"Camera ray and E operate the serialized register")
	check.call(retail.model.cash_cents-50000 == expected and retail.model.cash_cents == 50000+expected and retail.model.sales_count == 1,"Front-of-queue checkout completes while shop closed")
	check.call(not retail.model.has_order(front_id) and retail.queue.size() == 2,"Served customer leaves queue and order is consumed")
	check.call(retail.serve_next() == 0,"Immediate repeated E waits for next customer to advance")
	var advanced := await wait_for_queue(tree,retail,2)
	check.call(advanced,"Remaining buyers advance to new queue positions")
	if advanced:
		retail.serve_next()
		await wait_for_queue(tree,retail,1)
		retail.serve_next()
	check.call(retail.model.sales_count == 3 and retail.model.cash_cents == 57300,"Two booster and one hobby-box sales produce $573 cash")
	await frames(tree,700)
	check.call(retail.customers.is_empty() and retail.queue.is_empty(),"Served customers physically exit and are removed")
	check.call(hud.session.starter_packs_remaining == 3 and hud.session.collection.total_copies() == 0,"Retail sales do not consume personal starter packs or collection")
	retail.set_open(true)
	retail.spawn_remaining = 0.01
	retail.set_process(true)
	await frames(tree,5)
	check.call(retail.customers.size() == 1,"Open shop timer automatically admits a stocked-product customer")
	retail.set_open(false)
	shop.queue_free()
	await tree.process_frame
