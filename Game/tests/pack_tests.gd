class_name PackTests
extends RefCounted

static func run(check: Callable) -> void:
	var catalog: CardCatalog = load("res://data/cards/rookie_catalog.tres")
	var product: ProductDefinition = load("res://data/rookie_pack.tres")
	var box: ProductDefinition = load("res://data/rookie_box.tres")
	var rules := product.pack_definition
	check.call(rules.validation_errors(catalog).is_empty(),"M3 authored pack rules validate")
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 73
	b.seed = 73
	var drawn := rules.draw(catalog,a)
	check.call(drawn == rules.draw(catalog,b),"Same seed produces identical pack")
	check.call(drawn.size() == 3,"Rookie pack contains exactly three cards")
	var eligible := true
	for id in drawn:
		var card := catalog.find_card(id)
		eligible = eligible and card != null and card.card_set == product.card_set
	check.call(eligible,"Every draw belongs to the product's set")
	var rare_only := rules.duplicate() as CardPackDefinition
	rare_only.rarity_weights = {"rarity-rare":1.0}
	var duplicates := rare_only.draw(catalog,a)
	check.call(duplicates.size() == 3 and duplicates[0] == "card-rookie-2026-008" and duplicates[0] == duplicates[1] and duplicates[1] == duplicates[2],"Single-rarity pool draws with replacement and allows duplicates")
	var bad := rules.duplicate() as CardPackDefinition
	bad.rarity_weights = {"missing-rarity":1.0}
	check.call(not bad.validation_errors(catalog).is_empty() and bad.draw(catalog,a).is_empty(),"Unknown weighted rarity rejected with no draw")
	for weight in [0.0,-1.0,INF,NAN,"invalid"]:
		bad.rarity_weights = {"rarity-common":weight}
		check.call(not bad.validation_errors(catalog).is_empty(),"Invalid rarity weight rejected: " + str(weight))
	bad.rarity_weights = {}
	check.call(bad.draw(catalog,a).is_empty(),"Empty weight table cannot draw")
	bad = rules.duplicate() as CardPackDefinition
	bad.cards_per_pack = 0
	check.call(bad.draw(catalog,a).is_empty(),"Zero-card pack cannot draw")
	bad.cards_per_pack = 11
	check.call(bad.draw(catalog,a).is_empty(),"Oversize pack rejected")
	check.call(rules.draw(null,a).is_empty(),"Missing database cannot draw")
	var collection := CardCollection.new()
	check.call(collection.total_copies() == 0 and collection.unique_cards() == 0 and collection.count("missing") == 0,"Collection starts empty")
	check.call(collection.add_cards(duplicates,catalog),"Collection accepts valid drawn batch")
	check.call(collection.total_copies() == 3 and collection.unique_cards() == 1 and collection.count(duplicates[0]) == 3,"Duplicate counts and unique totals are correct")
	var invalid: Array[String] = ["card-rookie-2026-001","missing"]
	check.call(not collection.add_cards(invalid,catalog) and collection.total_copies() == 3,"Invalid batch is atomic: no partial collection grant")
	var session := PackSession.new(catalog)
	check.call(session.open_pack(box).is_empty() and session.starter_packs_remaining == 3,"Hobby box cannot consume a starter pack")
	check.call(session.open_pack(null).is_empty(),"Missing product rejected")
	for i in range(3):
		check.call(session.open_pack(product).size() == 3,"Starter pack opens: " + str(i+1))
	check.call(session.starter_packs_remaining == 0 and session.collection.total_copies() == 9,"Three starter packs produce exactly nine owned cards")
	check.call(session.open_pack(product).is_empty() and session.collection.total_copies() == 9,"Exhausted inventory cannot grant extra cards")
	check.call(PackSession.new(catalog).collection.total_copies() == 0,"New play session has an independent collection")
	var unsupported := product.duplicate() as ProductDefinition
	unsupported.card_set = null
	var safe_session := PackSession.new(catalog)
	check.call(safe_session.open_pack(unsupported).is_empty() and safe_session.starter_packs_remaining == 3,"Mismatched product/pack set cannot consume inventory")
	check.call(catalog.validation_errors().is_empty() and rules.rarity_weights["rarity-common"] == 70.0,"Pack tests preserve authored definitions and odds")

static func run_ui(hud: ShopHUD, check: Callable) -> void:
	var product: ProductDefinition = load("res://data/rookie_pack.tres")
	var box: ProductDefinition = load("res://data/rookie_box.tres")
	hud.close_inspection()
	hud.resume()
	hud.inspect_product(box)
	check.call(not hud.get_node(hud.open_button_path).visible,"Hobby box UI does not offer starter-pack opening")
	hud.close_inspection()
	hud.inspect_product(product)
	check.call(hud.get_node(hud.open_button_path).visible,"Booster inspection offers opening")
	hud.get_node(hud.open_button_path).pressed.emit()
	check.call(hud.reveal_panel.visible and hud.get_tree().paused and not hud.inspection.visible,"Open button enters paused card reveal")
	check.call(hud.session.starter_packs_remaining == 2 and hud.session.collection.total_copies() == 3,"Opening grants cards and consumes one pack once")
	hud.get_node(hud.open_button_path).pressed.emit()
	check.call(hud.session.starter_packs_remaining == 2 and hud.session.collection.total_copies() == 3,"Queued duplicate open click cannot grant another pack")
	check.call(hud.reveal_text.text.contains("CARD 1 / 3") and hud.reveal_is_new[0],"First card reveal shows progress and NEW status")
	hud.get_node(hud.next_button_path).pressed.emit()
	check.call(hud.reveal_index == 1,"Next button advances reveal")
	hud.get_node(hud.next_button_path).pressed.emit()
	hud.get_node(hud.next_button_path).pressed.emit()
	check.call(hud.collection_panel.visible and not hud.reveal_panel.visible and hud.get_tree().paused,"Final reveal opens paused collection")
	check.call(hud.collection_text.text.contains("3 copies") and hud.collection_text.text.contains("Owned ×"),"Collection shows copy totals and owned checklist entries")
	hud.get_node(hud.collection_close_path).pressed.emit()
	check.call(not hud.blocked() and not hud.get_tree().paused,"Collection close returns to playable shop")
	hud.inspect_product(product)
	hud.open_starter_pack()
	var escape := InputEventAction.new()
	escape.action = "pause"
	escape.pressed = true
	hud._unhandled_input(escape)
	check.call(not hud.blocked() and hud.session.collection.total_copies() == 6,"Escape skips remaining reveals without losing awarded cards")
	hud.inspect_product(product)
	hud.open_starter_pack()
	hud.finish_reveal()
	hud.inspect_product(product)
	check.call(not hud.get_node(hud.open_button_path).disabled and hud.session.collection.total_copies() == 9,"Spent starter inventory offers backroom opening")
	var before_stock := hud.retail.model.backroom_count(product.stable_id)
	hud.open_starter_pack()
	check.call(hud.session.collection.total_copies() == 12 and hud.session.starter_packs_remaining == 0 and hud.retail.model.backroom_count(product.stable_id) == before_stock-1,"Personal backroom opening consumes one stock unit and grants three cards")
	hud.finish_reveal()
	hud.close_inspection()
	var collection_key := InputEventAction.new()
	collection_key.action = "collection"
	collection_key.pressed = true
	hud._unhandled_input(collection_key)
	check.call(hud.collection_panel.visible and hud.collection_text.text.contains("Local save:"),"C opens collection and discloses save state")
	hud._unhandled_input(escape)
	check.call(not hud.blocked() and not hud.get_tree().paused,"Escape closes collection and resumes gameplay")
	# Force a one-card pool to verify new/duplicate presentation within one pack.
	var duplicate_product := product.duplicate() as ProductDefinition
	duplicate_product.pack_definition = product.pack_definition.duplicate() as CardPackDefinition
	duplicate_product.pack_definition.rarity_weights = {"rarity-rare":1.0}
	hud.session = PackSession.new(hud.session.catalog)
	hud.inspect_product(duplicate_product)
	hud.open_starter_pack()
	check.call(hud.reveal_is_new == [true,false,false],"Repeated card in one pack is NEW once, then DUPLICATE")
	hud.next_reveal()
	check.call(hud.reveal_text.text.contains("DUPLICATE") and hud.reveal_text.text.contains("Owned: 3"),"Duplicate reveal displays owned quantity")
	hud.finish_reveal()
