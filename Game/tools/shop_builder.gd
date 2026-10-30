class_name ShopBuilder
extends RefCounted
## One construction path for CLI, editor menu and regeneration tests.
const SCENE_PATH := "res://scenes/starter_shop.tscn"
const PACK = preload("res://data/rookie_pack.tres")
const BOX = preload("res://data/rookie_box.tres")

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "StarterShop"
	var wood := material(Color("81562e"))
	var cream := material(Color("e0d3ad"))
	var blue := material(Color("246eb5"))
	var red := material(Color("c44536"))
	var glass := material(Color(0.5, 0.8, 0.87, 0.22))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box(root, "Floor", Vector3(0,-0.15,0), Vector3(12,0.3,14), wood)
	box(root, "Ceiling", Vector3(0,4.2,0), Vector3(12,0.2,14), cream)
	box(root, "BackWall", Vector3(0,2,-7), Vector3(12,4,0.2), cream)
	for side in [-1, 1]:
		box(root, "SideWall", Vector3(side*6,2,0), Vector3(0.2,4,14), cream)
		box(root, "EntranceWall", Vector3(side*3.6,2,7), Vector3(4.8,4,0.2), cream)
		box(root, "PorchSide", Vector3(side*1.2,1.5,8), Vector3(0.2,3,2), cream)
	box(root, "EntranceLintel", Vector3(0,3.6,7), Vector3(2.4,1.2,0.2), blue)
	box(root, "PorchFloor", Vector3(0,-0.15,8), Vector3(2.4,0.3,2), wood)
	box(root, "PorchBoundary", Vector3(0,1.5,9), Vector3(2.4,3,0.2), glass)
	box(root, "Counter", Vector3(3,0.6,-3.3), Vector3(4,1.2,1), wood)
	for unit in range(3):
		var x: float = -4.0 + unit*4.0
		box(root, "ShelfBack", Vector3(x,1.4,-5.8), Vector3(2.5,2.8,0.2), wood)
		for side in [-1,1]:
			box(root, "ShelfSide", Vector3(x+side*1.2,1.4,-5.4), Vector3(0.15,2.8,0.9), wood)
		for level in range(3):
			var y: float = 0.35 + level*0.8
			box(root, "Shelf", Vector3(x,y,-5.4), Vector3(2.5,0.12,1), wood)
			for item in range(3):
				product(root, PACK if item%2 == 0 else BOX, Vector3(x+(item-1)*0.65,y+0.28,-5.25), blue if item%2 == 0 else red)
	box(root, "DisplayBase", Vector3(-3,0.45,0), Vector3(3,0.9,1.3), wood)
	box(root, "DisplayGlass", Vector3(-3,1.25,0), Vector3(3,0.08,1.3), glass)
	box(root, "DisplayGlassBack", Vector3(-3,1.1,-0.62), Vector3(3,0.4,0.06), glass)
	for side in [-1,1]:
		box(root, "DisplayGlassSide", Vector3(-3+side*1.47,1.1,0), Vector3(0.06,0.4,1.3), glass)
	product(root, PACK, Vector3(-3.4,1.1,0.1), blue)
	product(root, BOX, Vector3(-2.5,1.1,0.1), red)
	var sign := ShopSign.new()
	sign.name = "ShopSign"
	root.add_child(sign)
	sign.position = Vector3(1.5,1.6,-3.3)
	shape(sign,Vector3(0.7,0.5,0.08),red)
	var sign_label := Label3D.new()
	sign_label.name = "SignText"
	sign_label.text = "CLOSED"
	sign_label.font_size = 42
	sign_label.pixel_size = 0.003
	sign.add_child(sign_label)
	sign_label.position.z = 0.05
	sign.label_path = sign.get_path_to(sign_label)
	for x in [-4,0,4]:
		var light := OmniLight3D.new()
		light.name = "OverheadLight"
		root.add_child(light, true)
		light.position = Vector3(x,3.6,0)
		light.omni_range = 11
		light.light_energy = 2.2
		light.light_color = Color("ffe6bf")
		box(root, "Lamp", Vector3(x,3.85,0), Vector3(1.2,0.1,0.6), cream)
	var environment := WorldEnvironment.new()
	environment.name = "Environment"
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("29333d")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff0d2")
	environment.environment.ambient_light_energy = 0.5
	root.add_child(environment)
	var hud := make_hud(root)
	var player := FirstPersonPlayer.new()
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 1 | 4
	root.add_child(player)
	player.position = Vector3(0,0.05,4)
	var capsule := CollisionShape3D.new()
	capsule.name = "Capsule"
	capsule.shape = CapsuleShape3D.new()
	capsule.shape.radius = 0.3
	capsule.shape.height = 1.8
	player.add_child(capsule)
	capsule.position.y = 0.9
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.near = 0.05
	player.add_child(camera)
	camera.position.y = 1.65
	var interaction := InteractionController.new()
	interaction.name = "Interaction"
	player.add_child(interaction)
	interaction.camera_path = interaction.get_path_to(camera)
	interaction.hud_path = interaction.get_path_to(hud)
	player.camera_path = player.get_path_to(camera)
	player.hud_path = player.get_path_to(hud)
	player.interaction_path = player.get_path_to(interaction)
	own_children(root,root)
	return root

static func own_children(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		own_children(child,root)

static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.8
	return result

static func box(parent: Node, title: String, at: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = title
	parent.add_child(body, true)
	body.position = at
	# Glass blocks walking but lets inspection rays reach the displayed cards.
	if mat is StandardMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		body.collision_layer = 4
	shape(body,size,mat)
	return body

static func shape(body: StaticBody3D, size: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.material_override = mat
	body.add_child(mesh)
	var collider := CollisionShape3D.new()
	collider.name = "Collider"
	collider.shape = BoxShape3D.new()
	collider.shape.size = size
	body.add_child(collider)

static func product(parent: Node, definition: ProductDefinition, at: Vector3, mat: Material) -> void:
	var body := ProductInteractable.new()
	body.name = "Product"
	body.product = definition
	parent.add_child(body,true)
	body.position = at
	shape(body,Vector3(0.3,0.4,0.08) if definition.product_type == ProductDefinition.ProductType.BOOSTER_PACK else Vector3(0.45,0.4,0.4),mat)
	var label := Label3D.new()
	label.name = "ProductLabel"
	label.text = "ROOKIE\nPACK" if definition.product_type == ProductDefinition.ProductType.BOOSTER_PACK else "ROOKIE\nBOX"
	label.font_size = 32
	label.pixel_size = 0.002
	body.add_child(label)
	label.position.z = 0.05 if definition.product_type == ProductDefinition.ProductType.BOOSTER_PACK else 0.21

static func label(parent: Node, text: String, rect: Rect2, font_size: int = 22) -> Label:
	var result := Label.new()
	result.name = "Label"
	result.text = text
	result.position = rect.position
	result.size = rect.size
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size",font_size)
	parent.add_child(result,true)
	return result

static func panel(parent: Control, title: String) -> PanelContainer:
	var result := PanelContainer.new()
	result.name = title
	result.position = Vector2(290,150)
	result.size = Vector2(700,420)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172332")
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	result.add_theme_stylebox_override("panel",style)
	parent.add_child(result)
	result.hide()
	return result

static func make_hud(root: Node) -> ShopHUD:
	var hud := ShopHUD.new()
	hud.name = "HUD"
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(hud)
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(screen)
	var crosshair := label(screen,"+",Rect2(620,340,40,40),28)
	var prompt := label(screen,"",Rect2(90,605,1100,50))
	label(screen,"Cash: $500.00 (placeholder)",Rect2(20,15,420,45))
	label(screen,"WASD · Move    Shift · Sprint    E · Interact    Esc · Pause",Rect2(90,675,1100,35),18)
	var notice := label(screen,"",Rect2(140,65,1000,50))
	var inspection := panel(screen,"Inspection")
	var column := VBoxContainer.new()
	column.name = "Content"
	inspection.add_child(column)
	var text := Label.new()
	text.name = "ProductInfo"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("font_size",22)
	column.add_child(text)
	var close_button := Button.new()
	close_button.name = "Close"
	close_button.text = "Close inspection (Esc)"
	close_button.custom_minimum_size.y = 50
	column.add_child(close_button)
	var pause := panel(screen,"Pause")
	var menu := VBoxContainer.new()
	menu.name = "Menu"
	pause.add_child(menu)
	var heading := Label.new()
	heading.name = "Heading"
	heading.text = "PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.size_flags_vertical = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size",32)
	menu.add_child(heading)
	var resume_button := Button.new()
	resume_button.name = "Resume"
	resume_button.text = "Resume (Esc)"
	resume_button.custom_minimum_size.y = 50
	menu.add_child(resume_button)
	hud.prompt_path = hud.get_path_to(prompt)
	hud.crosshair_path = hud.get_path_to(crosshair)
	hud.notice_path = hud.get_path_to(notice)
	hud.inspection_path = hud.get_path_to(inspection)
	hud.product_text_path = hud.get_path_to(text)
	hud.pause_path = hud.get_path_to(pause)
	hud.close_button_path = hud.get_path_to(close_button)
	hud.resume_button_path = hud.get_path_to(resume_button)
	return hud

static func save_scene() -> Error:
	var root := build()
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK:
		DirAccess.make_dir_recursive_absolute("res://scenes")
		error = ResourceSaver.save(packed,SCENE_PATH)
	root.free()
	return error
