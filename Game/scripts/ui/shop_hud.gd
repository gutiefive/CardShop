class_name ShopHUD
extends CanvasLayer

@export var office_panel_path: NodePath
@export var office_text_path: NodePath
@export var office_button_path: NodePath
@export var order_pack_path: NodePath
@export var order_box_path: NodePath
@export var upgrade_path: NodePath
@export var save_button_path: NodePath
@export var new_shop_path: NodePath
@export var office_close_path: NodePath
@export var save_path: String = "user://shop_save_v1.json"
@onready var office_panel: PanelContainer = get_node(office_panel_path)
var save_store: ShopSaveStore
var save_status: String = "Initializing"
var persistence_ready: bool = false
var save_blocked: bool = false
var reset_confirmation: ConfirmationDialog
@export var retail_path: NodePath
@export var cash_path: NodePath
@export var retail_status_path: NodePath
@onready var retail: RetailDirector = get_node(retail_path)
@export var prompt_path: NodePath
@export var crosshair_path: NodePath
@export var notice_path: NodePath
@export var inspection_path: NodePath
@export var product_text_path: NodePath
@export var pause_path: NodePath
@export var close_button_path: NodePath
@export var resume_button_path: NodePath
@onready var prompt_label: Label = get_node(prompt_path)
@onready var crosshair: Label = get_node(crosshair_path)
@onready var notice_label: Label = get_node(notice_path)
@onready var inspection: PanelContainer = get_node(inspection_path)
@onready var product_text: Label = get_node(product_text_path)
@onready var pause_panel: PanelContainer = get_node(pause_path)
@export var open_button_path: NodePath
@export var reveal_panel_path: NodePath
@export var reveal_text_path: NodePath
@export var next_button_path: NodePath
@export var collection_button_path: NodePath
@export var collection_panel_path: NodePath
@export var collection_text_path: NodePath
@export var collection_close_path: NodePath
@onready var reveal_panel: PanelContainer = get_node(reveal_panel_path)
@onready var reveal_text: Label = get_node(reveal_text_path)
@onready var collection_panel: PanelContainer = get_node(collection_panel_path)
@onready var collection_text: Label = get_node(collection_text_path)
var session := PackSession.new(preload("res://data/cards/rookie_catalog.tres"))
var inspected_product: ProductDefinition
var revealed_ids: Array[String] = []
var reveal_is_new: Array[bool] = []
var reveal_index: int = 0
var notice_remaining: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_node(office_button_path).pressed.connect(show_office)
	get_node(order_pack_path).pressed.connect(order_pack_stock)
	get_node(order_box_path).pressed.connect(order_box_stock)
	get_node(upgrade_path).pressed.connect(upgrade_backroom)
	get_node(save_button_path).pressed.connect(save_game)
	get_node(new_shop_path).pressed.connect(confirm_new_shop)
	get_node(office_close_path).pressed.connect(close_office)
	retail.model.changed.connect(_on_economy_changed)
	reset_confirmation = ConfirmationDialog.new()
	reset_confirmation.dialog_text = "Start a new shop? Your current save files will be archived locally. Cash, stock and collection will restart."
	reset_confirmation.confirmed.connect(start_new_shop)
	add_child(reset_confirmation)
	office_panel.hide()
	if persistence_enabled():
		get_tree().auto_accept_quit = false
		get_tree().root.close_requested.connect(_on_window_close)
	get_node(close_button_path).pressed.connect(close_inspection)
	get_node(resume_button_path).pressed.connect(resume)
	get_node(open_button_path).pressed.connect(open_starter_pack)
	get_node(next_button_path).pressed.connect(next_reveal)
	get_node(collection_button_path).pressed.connect(show_collection)
	get_node(collection_close_path).pressed.connect(close_collection)
	reveal_panel.hide()
	collection_panel.hide()
	inspection.hide()
	pause_panel.hide()
	_sync_mode()

func blocked() -> bool:
	return inspection.visible or pause_panel.visible or reveal_panel.visible or collection_panel.visible or office_panel.visible

func _sync_mode() -> void:
	get_tree().paused = blocked()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if blocked() else Input.MOUSE_MODE_CAPTURED
	if blocked():
		set_focus("")

func set_focus(text: String) -> void:
	prompt_label.text = text
	crosshair.modulate = Color(1, 0.85, 0.2) if not text.is_empty() else Color.WHITE

func inspect_product(product: ProductDefinition) -> void:
	inspected_product = product
	product_text.text = "%s\n\n%s\n\nWholesale: %s   Retail: %s\n\nPersonal starter packs are separate from shop stock" % [product.display_name, product.description, ProductDefinition.format_price(product.purchase_cents), ProductDefinition.format_price(product.retail_cents)]
	if product.card_set:
		product_text.text += "\n\nSet: %s · %d cards" % [product.card_set.display_name, product.card_set.expected_card_count]
	var open_button: Button = get_node(open_button_path)
	open_button.visible = product.pack_definition != null
	var backroom_packs := retail.model.backroom_count(product.stable_id)
	open_button.disabled = session.starter_packs_remaining <= 0 and backroom_packs <= 0
	open_button.text = "Open free starter pack (%d left)" % session.starter_packs_remaining if session.starter_packs_remaining > 0 else "Open backroom pack (%d available)" % backroom_packs
	if not product.pack_definition:
		product_text.text += "\nHobby box opening is not included yet. Inspect a booster pack to open."
	inspection.show()
	get_node(close_button_path).grab_focus()
	_sync_mode()

func close_inspection() -> void:
	inspection.hide()
	_sync_mode()

func resume() -> void:
	pause_panel.hide()
	_sync_mode()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("office") and not blocked():
		show_office()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("collection") and not blocked():
		show_collection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		if office_panel.visible:
			close_office()
		elif reveal_panel.visible:
			finish_reveal()
		elif collection_panel.visible:
			close_collection()
		elif inspection.visible:
			close_inspection()
		else:
			pause_panel.visible = not pause_panel.visible
			if pause_panel.visible:
				get_node(resume_button_path).grab_focus()
			_sync_mode()
		get_viewport().set_input_as_handled()

func open_starter_pack() -> void:
	# Hiding inspection also protects against a queued second click.
	if not inspection.visible:
		return
	var before: Dictionary = {}
	for card in session.catalog.cards:
		before[card.stable_id] = session.collection.count(card.stable_id)
	var use_starter := session.starter_packs_remaining > 0
	if not use_starter and (not inspected_product or retail.model.backroom_count(inspected_product.stable_id) < 1):
		notify("Order booster stock in the office (B) first.")
		return
	var ids := session.open_pack(inspected_product,use_starter)
	if ids.is_empty():
		notify("No starter packs available, or pack definition invalid.")
		return
	if not use_starter:
		# No await or other action can intervene between validation/draw and stock debit.
		retail.model.consume_backroom(inspected_product.stable_id)
	save_game()
	revealed_ids = ids
	reveal_is_new.clear()
	for id in ids:
		reveal_is_new.append(int(before.get(id,0)) == 0)
		before[id] = int(before.get(id,0)) + 1
	reveal_index = 0
	inspection.hide()
	reveal_panel.show()
	show_reveal()
	_sync_mode()

func show_reveal() -> void:
	var card := session.catalog.find_card(revealed_ids[reveal_index])
	reveal_text.text = "CARD %d / %d     ·     %s\n\n#%03d  %s\n%s\n\n%s · %s\n\n%s\n\nBase value: %s     Owned: %d\n\nAll pack cards are already in your collection. Esc keeps them." % [reveal_index+1,revealed_ids.size(),"NEW!" if reveal_is_new[reveal_index] else "DUPLICATE",card.card_number,card.display_name(),card.player.team_name,card.rarity.display_name,card.card_set.display_name,card.player.biography,ProductDefinition.format_price(card.base_value_cents),session.collection.count(card.stable_id)]
	reveal_text.modulate = card.rarity.accent_color
	var next_button: Button = get_node(next_button_path)
	next_button.text = "Next card" if reveal_index < revealed_ids.size()-1 else "Finish · View collection"
	next_button.grab_focus()

func next_reveal() -> void:
	if not reveal_panel.visible:
		return
	if reveal_index < revealed_ids.size()-1:
		reveal_index += 1
		show_reveal()
	else:
		reveal_panel.hide()
		show_collection()

func finish_reveal() -> void:
	reveal_panel.hide()
	_sync_mode()

func show_collection() -> void:
	if reveal_panel.visible or inspection.visible:
		return
	pause_panel.hide()
	collection_panel.show()
	var text := "COLLECTION · %d / %d unique · %d copies\nStarter packs: %d · Local save: %s\n\n" % [session.collection.unique_cards(),session.catalog.cards.size(),session.collection.total_copies(),session.starter_packs_remaining,save_status]
	for card_set in session.catalog.sets:
		for card in session.catalog.cards_for_set(card_set.stable_id):
			var copies := session.collection.count(card.stable_id)
			text += "#%03d  %s · %s · %s\n" % [card.card_number,card.display_name(),card.rarity.display_name,"Owned ×%d" % copies if copies else "Not owned"]
	collection_text.text = text
	get_node(collection_close_path).grab_focus()
	_sync_mode()

func close_collection() -> void:
	collection_panel.hide()
	_sync_mode()

func persistence_enabled() -> bool:
	return not ProjectSettings.get_meta("cardshop_disable_persistence",false) and not OS.get_cmdline_user_args().has("--no-save")

func initialize_persistence() -> void:
	save_store = ShopSaveStore.new(save_path)
	if not persistence_enabled():
		save_status = "Disabled for tests"
		persistence_ready = true
		return
	if save_store.exists():
		if save_store.load_into(retail.model,session):
			save_status = "Loaded backup" if save_store.loaded_backup else "Loaded"
			retail.refresh_shelves()
			if save_store.loaded_backup:
				notify("Recovered the previous checkpoint from backup.")
		else:
			save_blocked = true
			save_status = save_store.error + "; protected from overwrite"
			notify("Save could not load. Open office (B) for status or New shop.")
	else:
		save_status = "New shop"
	persistence_ready = true
	if not save_blocked:
		save_game()

func save_game() -> bool:
	if not persistence_enabled():
		return true
	if not persistence_ready or save_blocked:
		return false
	if save_store.save(retail.model,session):
		save_status = "Saved"
	else:
		save_status = save_store.error
		notify("Save failed. Check office (B): " + save_status)
	if office_panel.visible:
		refresh_office()
	return save_status == "Saved"

func _on_economy_changed() -> void:
	if persistence_ready:
		save_game()
	if office_panel.visible:
		refresh_office()

func show_office() -> void:
	if inspection.visible or reveal_panel.visible or collection_panel.visible:
		return
	pause_panel.hide()
	office_panel.show()
	refresh_office()
	get_node(office_close_path).grab_focus()
	_sync_mode()

func refresh_office() -> void:
	var model := retail.model
	var next := model.next_level_sales()
	var progress := "%d / %d sales toward next level" % [model.sales_count,next] if next else "Maximum shop level reached"
	get_node(office_text_path).text = "SHOP OFFICE · Level %d: %s\n%s\nCash %s · Revenue %s · Spent %s\nBackroom: %d/%d boosters · %d/%d boxes\nOrders arrive instantly at wholesale cost. Shelf stock is separate.\nLocal save: %s" % [model.level(),model.level_name(),progress,ProductDefinition.format_price(model.cash_cents),ProductDefinition.format_price(model.revenue_cents),ProductDefinition.format_price(model.expenses_cents),model.backroom_count("rookie-series-pack"),model.backroom_capacity("rookie-series-pack"),model.backroom_count("rookie-series-box"),model.backroom_capacity("rookie-series-box"),save_status]
	get_node(order_pack_path).disabled = not model.can_order_stock("rookie-series-pack",6)
	get_node(order_box_path).disabled = not model.can_order_stock("rookie-series-box",1)
	var upgrade: Button = get_node(upgrade_path)
	upgrade.disabled = not model.can_upgrade_backroom()
	upgrade.text = "Larger backroom purchased (48 packs / 12 boxes)" if model.backroom_expanded else "Expand backroom · $100 · Requires 5 sales (Level 2)"

func order_pack_stock() -> void:
	order_stock("rookie-series-pack",6)

func order_box_stock() -> void:
	order_stock("rookie-series-box",1)

func order_stock(id: String, quantity: int) -> void:
	var cost := retail.model.order_stock(id,quantity)
	notify("Delivery added to backroom: " + ProductDefinition.format_price(cost) if cost else "Cannot order: insufficient cash or backroom space")
	refresh_office()

func upgrade_backroom() -> void:
	notify("Backroom expanded!" if retail.model.upgrade_backroom() else "Upgrade requires 5 sales, $100 and no previous upgrade")
	refresh_office()

func close_office() -> void:
	office_panel.hide()
	_sync_mode()

func confirm_new_shop() -> void:
	reset_confirmation.popup_centered()

func start_new_shop() -> void:
	if not save_store.archive():
		notify(save_store.error)
		return
	persistence_ready = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_window_close() -> void:
	if save_game():
		get_tree().quit()
	else:
		notify("Cannot save before closing. Check office (B) and its save status.")

func notify(message: String) -> void:
	notice_label.text = message
	notice_remaining = 3.0

func _process(delta: float) -> void:
	get_node(cash_path).text = "Cash: %s · Sold: %d · Lv %d" % [ProductDefinition.format_price(retail.model.cash_cents),retail.model.sales_count,retail.model.level()]
	get_node(retail_status_path).text = "%s · Customers: %d · Queue: %d · Backroom: %d packs / %d boxes" % ["OPEN" if retail.shop_open else "CLOSED",retail.customers.size(),retail.queue.size(),retail.model.backroom_count("rookie-series-pack"),retail.model.backroom_count("rookie-series-box")]
	notice_remaining = maxf(0.0, notice_remaining - delta)
	if notice_remaining == 0.0:
		notice_label.text = ""

func _exit_tree() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
