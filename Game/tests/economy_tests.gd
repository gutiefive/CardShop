class_name EconomyTests
extends RefCounted
const PACK = preload("res://data/rookie_pack.tres")
const BOX = preload("res://data/rookie_box.tres")
const CATALOG = preload("res://data/cards/rookie_catalog.tres")

static func model() -> RetailSession:
	var result := RetailSession.new(PACK,BOX)
	result.register_shelf("packs",PACK,9)
	result.register_shelf("boxes",BOX,9)
	return result

static func run(check: Callable) -> void:
	var retail := model()
	check.call(retail.level() == 1 and retail.next_level_sales() == 5,"M5 begins at level 1 with five-sale target")
	check.call(retail.order_stock(PACK.stable_id,6) == 1200 and retail.cash_cents == 48800 and retail.backroom_count(PACK.stable_id) == 18,"Wholesale booster delivery debits exact cash and adds six units")
	check.call(retail.order_stock(BOX.stable_id,1) == 4000 and retail.cash_cents == 44800 and retail.expenses_cents == 5200,"Hobby-box order updates purchase ledger")
	retail.order_stock(PACK.stable_id,6)
	var before := retail.snapshot()
	check.call(retail.order_stock(PACK.stable_id,1) == 0 and retail.snapshot() == before,"Full backroom rejects entire order without cash/stock mutation")
	check.call(retail.order_stock("missing",1) == 0 and retail.order_stock(PACK.stable_id,0) == 0 and retail.order_stock(PACK.stable_id,-1) == 0,"Invalid wholesale product/quantity rejected")
	var poor := model()
	poor.cash_cents = 100
	check.call(poor.order_stock(BOX.stable_id,1) == 0 and poor.cash_cents == 100 and poor.backroom_count(BOX.stable_id) == 3,"Insufficient funds cannot partially order")
	check.call(not retail.upgrade_backroom(),"Backroom upgrade locked below level 2")
	retail.stock_shelf("packs")
	for i in range(5):
		retail.reserve(i+1,"packs")
		retail.complete_sale(i+1)
	check.call(retail.level() == 2 and retail.next_level_sales() == 15 and retail.revenue_cents == 2000,"Five paid sales unlock level 2 and record revenue")
	var cash := retail.cash_cents
	check.call(retail.upgrade_backroom() and retail.cash_cents == cash-10000 and retail.backroom_capacity(PACK.stable_id) == 48 and retail.backroom_capacity(BOX.stable_id) == 12,"Upgrade charges once and doubles backroom capacity")
	check.call(not retail.upgrade_backroom() and retail.cash_cents == cash-10000,"Repeated upgrade cannot charge twice")
	check.call(retail.order_stock(PACK.stable_id,6) == 1200,"Expanded backroom accepts additional stock")
	check.call(retail.cash_cents == 50000+retail.revenue_cents-retail.expenses_cents,"Cash reconciles with revenue and expense ledger")
	var data := retail.snapshot()
	var restored := model()
	check.call(restored.restore_snapshot(data) and restored.snapshot() == data,"Retail snapshot round-trips cash, stock, progression and upgrade")
	data.cash += 1
	check.call(not restored.restore_snapshot(data),"Tampered ledger rejected atomically")
	check.call(restored.cash_cents == retail.cash_cents,"Failed retail restore keeps previous state")
	data = retail.snapshot()
	data.shelves.packs = 10
	check.call(not restored.restore_snapshot(data),"Saved shelf overflow rejected")
	data = retail.snapshot()
	data.backroom[PACK.stable_id] = -1
	check.call(not restored.restore_snapshot(data),"Negative saved stock rejected")
	data = retail.snapshot()
	data.sales = 1.25
	check.call(not restored.restore_snapshot(data),"Fractional saved counts rejected")
	data = retail.snapshot()
	data.backroom["unknown"] = 1
	check.call(not restored.restore_snapshot(data),"Unknown saved inventory ID rejected")
	var held := model()
	held.stock_shelf("packs")
	held.reserve(42,"packs")
	var checkpoint := held.snapshot()
	check.call(held.shelf_count("packs") == 8 and checkpoint.shelves.packs == 9 and held.has_order(42),"Checkpoint returns held unit only in snapshot without mutating live order")
	var loaded := model()
	loaded.restore_snapshot(checkpoint)
	check.call(loaded.shelf_count("packs") == 9 and not loaded.has_order(42),"Reload recovers held stock with no stale customer order")
	held.stock_shelf("packs")
	checkpoint = held.snapshot()
	check.call(checkpoint.shelves.packs == 9 and checkpoint.backroom[PACK.stable_id] == held.backroom_count(PACK.stable_id)+1,"Checkpoint preserves held stock even after shelf refilled")
	var packs := PackSession.new(CATALOG)
	packs.rng.seed = 734
	packs.open_pack(PACK)
	var personal := packs.snapshot()
	var packs_loaded := PackSession.new(CATALOG)
	check.call(packs_loaded.restore_snapshot(personal) and packs_loaded.collection.total_copies() == 3 and packs_loaded.starter_packs_remaining == 2,"Personal pack/collection snapshot round-trips")
	check.call(packs.open_pack(PACK) == packs_loaded.open_pack(PACK),"Saved RNG resumes exact next draw")
	personal.collection["unknown-card"] = 1
	var before_copies := packs_loaded.collection.total_copies()
	check.call(not packs_loaded.restore_snapshot(personal) and packs_loaded.collection.total_copies() == before_copies,"Unknown collected card rejects personal restore atomically")
	check.call(not SaveValues.whole(NAN) and not SaveValues.whole("1") and not SaveValues.whole(1.5) and SaveValues.whole(1.0),"JSON value validation accepts whole finite numbers only")

static func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

static func run_files(check: Callable) -> void:
	var folder := "user://m5_tests_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder+"/checkpoint.json"
	var store := ShopSaveStore.new(path)
	var retail := model()
	var packs := PackSession.new(CATALOG)
	check.call(not store.load_into(retail,packs) and not store.exists(),"Absent save is detected without changing a fresh shop")
	retail.order_stock(PACK.stable_id,6)
	packs.open_pack(PACK)
	check.call(store.save(retail,packs),"Versioned JSON checkpoint writes successfully")
	var old_cash := retail.cash_cents
	retail.order_stock(BOX.stable_id,1)
	check.call(store.save(retail,packs) and FileAccess.file_exists(path+".bak"),"Replacing checkpoint retains prior valid backup")
	var restored := model()
	var personal := PackSession.new(CATALOG)
	check.call(store.load_into(restored,personal) and restored.cash_cents == retail.cash_cents and personal.collection.total_copies() == 3,"Disk load restores economy and collection together")
	write_json(path,{"version":999})
	check.call(store.load_into(restored,personal) and store.loaded_backup and restored.cash_cents == old_cash,"Unsupported primary recovers the prior valid backup")
	var valid_backup := FileAccess.get_file_as_string(path+".bak")
	check.call(store.save(restored,personal) and FileAccess.get_file_as_string(path+".bak") == valid_backup,"Saving recovered state preserves a good backup instead of corrupt primary")
	var malformed := {"version":1,"retail":retail.snapshot(),"packs":packs.snapshot()}
	malformed.packs.collection["unknown"] = 1
	write_json(path,malformed)
	write_json(path+".bak",{"version":999})
	var previous_cash := restored.cash_cents
	var previous_packs := personal.starter_packs_remaining
	check.call(not store.load_into(restored,personal) and restored.cash_cents == previous_cash and personal.starter_packs_remaining == previous_packs,"Invalid primary and backup cannot partially mutate live state")
	check.call(store.archive() and not store.exists(),"New-shop archival preserves old files outside active checkpoint names")
	var bad_store := ShopSaveStore.new(folder+"/missing/invalid.json")
	check.call(not bad_store.save(retail,packs) and not bad_store.error.is_empty(),"Unwritable destination reports a save failure")
	# Delete only files in this uniquely created test folder.
	for name in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder+"/"+name)
	DirAccess.remove_absolute(folder)

static func frames(tree: SceneTree, count: int) -> void:
	for i in range(count):
		await tree.physics_frame

static func scene_hud(shop: Node) -> ShopHUD:
	for child in shop.get_children():
		if child is ShopHUD:
			return child
	return null

static func run_scene(tree: SceneTree, check: Callable) -> void:
	var folder := "user://m5_ui_tests_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder+"/checkpoint.json"
	var packed: PackedScene = load(ShopBuilder.SCENE_PATH)
	var shop := packed.instantiate()
	var hud := scene_hud(shop)
	hud.save_path = path
	ProjectSettings.set_meta("cardshop_disable_persistence",false)
	tree.root.add_child(shop)
	await frames(tree,4)
	check.call(hud.persistence_ready and FileAccess.file_exists(path) and hud.save_status == "Saved","Fresh scene initializes an isolated autosave checkpoint")
	var office := InputEventAction.new()
	office.action = "office"
	office.pressed = true
	hud._unhandled_input(office)
	check.call(hud.office_panel.visible and tree.paused,"B opens office and pauses shop simulation")
	hud.get_node(hud.order_pack_path).pressed.emit()
	check.call(hud.retail.model.cash_cents == 48800 and hud.retail.model.backroom_count(PACK.stable_id) == 18,"Office order button buys six boosters at wholesale")
	check.call(FileAccess.get_file_as_string(path).contains("48800"),"Wholesale order triggers immediate autosave")
	hud.retail.shelves[0].interact(hud)
	hud.close_office()
	hud.inspect_product(PACK)
	hud.open_starter_pack()
	check.call(hud.session.collection.total_copies() == 3 and hud.session.starter_packs_remaining == 2,"Pack opening updates personal saved state")
	hud.finish_reveal()
	hud.retail.model.reserve(777,hud.retail.shelves[0].shelf_id)
	check.call(hud.retail.model.shelf_count(hud.retail.shelves[0].shelf_id) == 8,"Live held unit removed before simulated restart")
	shop.queue_free()
	await tree.process_frame
	shop = packed.instantiate()
	hud = scene_hud(shop)
	hud.save_path = path
	tree.root.add_child(shop)
	await frames(tree,4)
	check.call(hud.retail.model.cash_cents == 48800 and hud.retail.model.backroom_count(PACK.stable_id) == 9,"New scene automatically restores cash and ordered inventory")
	check.call(hud.retail.model.shelf_count(hud.retail.shelves[0].shelf_id) == 9 and not hud.retail.model.has_order(777),"Restart returns held item to shelf without a ghost order")
	check.call(hud.session.collection.total_copies() == 3 and hud.session.starter_packs_remaining == 2,"New scene automatically restores collection and starter pack count")
	check.call(not hud.retail.shop_open and hud.retail.customers.is_empty(),"Loaded shop starts closed with customers reset")
	for i in range(5):
		hud.retail.model.reserve(i+1,hud.retail.shelves[0].shelf_id)
		hud.retail.model.complete_sale(i+1)
	hud.show_office()
	check.call(not hud.get_node(hud.upgrade_path).disabled,"Five sales enable office upgrade button")
	hud.get_node(hud.upgrade_path).pressed.emit()
	check.call(hud.retail.model.backroom_expanded and hud.retail.model.cash_cents == 40800,"Office upgrade buys expanded backroom and autosaves")
	hud.get_node(hud.save_button_path).pressed.emit()
	check.call(hud.save_status == "Saved" and hud.get_node(hud.office_text_path).text.contains("Local Favorite"),"Manual Save button reports success and office shows progression")
	hud.get_node(hud.new_shop_path).pressed.emit()
	check.call(hud.reset_confirmation.visible,"New shop button requires an explicit confirmation dialog")
	hud.reset_confirmation.hide()
	hud.close_office()
	shop.queue_free()
	await tree.process_frame
	write_json(path,{"version":999})
	write_json(path+".bak",{"version":999})
	shop = packed.instantiate()
	hud = scene_hud(shop)
	hud.save_path = path
	tree.root.add_child(shop)
	await frames(tree,4)
	hud.retail.model.order_stock(PACK.stable_id,6)
	check.call(hud.save_blocked and not hud.save_game() and FileAccess.get_file_as_string(path).contains("999"),"Invalid saved shop is protected from automatic or manual overwrite")
	# Exercise real scene reload after explicit new-shop confirmation; disable only
	# the new default-path scene's disk access so no real user checkpoint is touched.
	tree.current_scene = shop
	ProjectSettings.set_meta("cardshop_disable_persistence",true)
	hud.start_new_shop()
	await frames(tree,6)
	var restarted := tree.current_scene
	var fresh := scene_hud(restarted)
	check.call(fresh.retail.model.cash_cents == 50000 and fresh.session.collection.total_copies() == 0 and fresh.session.starter_packs_remaining == 3,"Confirmed new shop reloads fresh economy and personal inventory")
	check.call(not FileAccess.file_exists(path) and DirAccess.get_files_at(folder).size() >= 2,"New shop archives the old primary and backup instead of deleting them")
	tree.current_scene = null
	restarted.queue_free()
	await tree.process_frame
	tree.auto_accept_quit = true
	for name in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder+"/"+name)
	DirAccess.remove_absolute(folder)
