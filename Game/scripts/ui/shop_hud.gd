class_name ShopHUD
extends CanvasLayer

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
var notice_remaining: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_node(close_button_path).pressed.connect(close_inspection)
	get_node(resume_button_path).pressed.connect(resume)
	inspection.hide()
	pause_panel.hide()
	_sync_mode()

func blocked() -> bool:
	return inspection.visible or pause_panel.visible

func _sync_mode() -> void:
	get_tree().paused = blocked()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if blocked() else Input.MOUSE_MODE_CAPTURED
	if blocked():
		set_focus("")

func set_focus(text: String) -> void:
	prompt_label.text = text
	crosshair.modulate = Color(1, 0.85, 0.2) if not text.is_empty() else Color.WHITE

func inspect_product(product: ProductDefinition) -> void:
	product_text.text = "%s\n\n%s\n\nWholesale: %s   Retail: %s\n\nInspection only · no purchasing or pack opening" % [product.display_name, product.description, ProductDefinition.format_price(product.purchase_cents), ProductDefinition.format_price(product.retail_cents)]
	if product.card_set:
		product_text.text += "\n\nSet: %s · %d cards" % [product.card_set.display_name, product.card_set.expected_card_count]
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
	if event.is_action_pressed("pause"):
		if inspection.visible:
			close_inspection()
		else:
			pause_panel.visible = not pause_panel.visible
			if pause_panel.visible:
				get_node(resume_button_path).grab_focus()
			_sync_mode()
		get_viewport().set_input_as_handled()

func notify(message: String) -> void:
	notice_label.text = message
	notice_remaining = 3.0

func _process(delta: float) -> void:
	notice_remaining = maxf(0.0, notice_remaining - delta)
	if notice_remaining == 0.0:
		notice_label.text = ""

func _exit_tree() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
