class_name FirstPersonPlayer
extends CharacterBody3D

@export var camera_path: NodePath
@export var hud_path: NodePath
@export var interaction_path: NodePath
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.0
@export var acceleration: float = 14.0
@export var mouse_sensitivity: float = 0.002
@onready var camera: Camera3D = get_node(camera_path)
@onready var hud: ShopHUD = get_node(hud_path)
@onready var interaction: InteractionController = get_node(interaction_path)
var pitch: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if hud.blocked():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_look(event.relative)
	if event.is_action_pressed("interact"):
		interaction.try_interact()

func apply_look(relative: Vector2) -> void:
	rotate_y(-relative.x * mouse_sensitivity)
	pitch = clampf(pitch - relative.y * mouse_sensitivity, deg_to_rad(-85), deg_to_rad(85))
	camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := transform.basis * Vector3(axis.x, 0, axis.y)
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	interaction.update_focus()
