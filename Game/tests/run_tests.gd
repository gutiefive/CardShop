extends SceneTree
## Dependency-free tests: data, packed references, real physics, raycasts and UI state.
var checks: int = 0
var failures: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _initialize() -> void:
	call_deferred("run")

func nodes_of_type(node: Node, type_script: Script) -> Array[Node]:
	var result: Array[Node] = []
	if node.get_script() == type_script:
		result.append(node)
	for child in node.get_children():
		result.append_array(nodes_of_type(child,type_script))
	return result

func signature(node: Node) -> PackedStringArray:
	var result := PackedStringArray([str(node.name) + ":" + node.get_class()])
	for child in node.get_children():
		result.append_array(signature(child))
	return result

func key_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	CatalogTests.run(check)
	PackTests.run(check)
	var pack: ProductDefinition = load("res://data/rookie_pack.tres")
	var box: ProductDefinition = load("res://data/rookie_box.tres")
	check(pack.validation_errors().is_empty() and box.validation_errors().is_empty(),"Both authored products validate")
	check(pack.stable_id != box.stable_id,"Products have unique stable IDs")
	check(ProductDefinition.format_price(400) == "$4.00","Money uses integer cents and displays correctly")
	var bad := ProductDefinition.new()
	check(not bad.validation_errors().is_empty(),"Empty definition rejected")
	bad.stable_id = "test"
	bad.display_name = "Test"
	bad.description = "Test"
	bad.purchase_cents = -1
	check(not bad.validation_errors().is_empty(),"Negative cost rejected")
	bad.purchase_cents = 500
	bad.retail_cents = 400
	check(not bad.validation_errors().is_empty(),"Retail below cost rejected")
	for action in ["move_forward","move_back","move_left","move_right","sprint","interact","pause","collection"]:
		check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(),"Input action bound: " + action)
	check((InputMap.action_get_events("sprint")[0] as InputEventKey).physical_keycode == KEY_SHIFT,"Sprint uses physical Shift")
	check((InputMap.action_get_events("pause")[0] as InputEventKey).physical_keycode == KEY_ESCAPE,"Pause uses Escape")
	var first := ShopBuilder.build()
	var second := ShopBuilder.build()
	check(signature(first) == signature(second),"Repeated generation preserves hierarchy and counts")
	check(nodes_of_type(first,preload("res://scripts/interaction/product_interactable.gd")).size() == 29,"Shop has 29 sample products")
	check(nodes_of_type(first,preload("res://scripts/player/first_person_player.gd")).size() == 1,"Exactly one player per generation")
	first.free()
	second.free()
	var packed: PackedScene = load(ShopBuilder.SCENE_PATH)
	var shop := packed.instantiate()
	root.add_child(shop)
	await frames(4)
	var players := nodes_of_type(shop,preload("res://scripts/player/first_person_player.gd"))
	var player: FirstPersonPlayer = players[0]
	var hud: ShopHUD = player.hud
	check(player.camera != null and player.interaction.hud == hud,"Serialized camera/HUD/interaction references survive scene packing")
	await frames(30)
	check(player.is_on_floor(),"Character settles on shop floor")
	var start := player.position
	Input.action_press("move_forward")
	await frames(30)
	Input.action_release("move_forward")
	check(player.position.z < start.z - 0.5,"W input moves player forward through physics")
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await frames(30)
	check(absf(player.velocity.z) > player.walk_speed + 0.5,"Sprint increases movement speed")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	# Move toward the side wall; CharacterBody must stop at its capsule radius.
	player.position = Vector3(5.2,0.05,2)
	player.velocity = Vector3.ZERO
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(player.position.x < 5.65 and player.position.x > 5.3,"Player collides with side wall")
	# Camera rays target an exposed display pack, not a hardcoded object name.
	var products := nodes_of_type(shop,preload("res://scripts/interaction/product_interactable.gd"))
	var display: ProductInteractable
	for candidate in products:
		if candidate.position.z > -1 and candidate.product == pack:
			display = candidate
	player.position = Vector3(-3.4,0.05,2)
	player.velocity = Vector3.ZERO
	await frames(3)
	player.camera.look_at(display.global_position)
	player.interaction.update_focus()
	check(player.interaction.focus == display,"Camera ray focuses an in-range product")
	check(hud.prompt_label.text.contains(pack.display_name),"Focus HUD displays product name")
	player._unhandled_input(key_event("interact"))
	check(hud.inspection.visible and paused,"E opens inspection and pauses gameplay")
	check(hud.product_text.text.contains("$4.00") and hud.product_text.text.contains(pack.display_name),"Inspection shows authored name and retail price")
	check(hud.product_text.text.contains("2026 Rookie Series") and hud.product_text.text.contains("8 cards"),"Product inspection identifies its card set and checklist size")
	var frozen := player.position
	Input.action_press("move_forward")
	await frames(5)
	Input.action_release("move_forward")
	check(player.position.is_equal_approx(frozen),"Inspection blocks player physics movement")
	hud.get_node(hud.close_button_path).pressed.emit()
	check(not hud.blocked() and not paused,"Serialized Close button resumes gameplay")
	player.interaction.interaction_range = 0.2
	player.interaction.update_focus()
	check(player.interaction.focus == null,"Out-of-range products cannot be focused")
	player.interaction.interaction_range = 3.0
	# Occlusion is tested with a temporary world-layer blocker.
	var blocker := ShopBuilder.box(shop,"TestBlocker",Vector3(-3.4,1.35,1.0),Vector3(1,1,0.2),ShopBuilder.material(Color.WHITE))
	await frames(3)
	player.interaction.update_focus()
	check(player.interaction.focus == null,"Solid geometry blocks product interaction")
	blocker.queue_free()
	await frames(3)
	var signs := nodes_of_type(shop,preload("res://scripts/interaction/shop_sign.gd"))
	var sign: ShopSign = signs[0]
	player.position = Vector3(1.5,0.05,-1.4)
	player.velocity = Vector3.ZERO
	await frames(3)
	player.camera.look_at(sign.global_position)
	player.interaction.try_interact()
	check(sign.is_open and hud.notice_label.text.contains("OPEN"),"Sign ray interaction toggles shop status")
	hud._unhandled_input(key_event("pause"))
	check(hud.pause_panel.visible and paused,"Escape opens pause menu")
	hud.get_node(hud.resume_button_path).pressed.emit()
	check(not paused and not hud.pause_panel.visible,"Resume button exits pause")
	hud.inspect_product(box)
	hud._unhandled_input(key_event("pause"))
	check(not paused and not hud.inspection.visible,"Escape dismisses inspection")
	# Headless display cannot capture a physical mouse; test the same look calculation.
	player.apply_look(Vector2(40,100000))
	check(not is_zero_approx(player.rotation.y) and is_equal_approx(player.pitch,deg_to_rad(-85)),"Look calculation changes yaw and clamps pitch")
	PackTests.run_ui(hud,check)
	shop.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
