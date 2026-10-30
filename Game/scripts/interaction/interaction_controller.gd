class_name InteractionController
extends Node

@export var camera_path: NodePath
@export var hud_path: NodePath
@export_range(0.1, 10.0) var interaction_range: float = 3.0
@onready var camera: Camera3D = get_node(camera_path)
@onready var hud: ShopHUD = get_node(hud_path)
var focus: Interactable

func update_focus() -> void:
	focus = null
	if hud.blocked():
		hud.set_focus("")
		return
	var start := camera.global_position
	var end := start - camera.global_basis.z * interaction_range
	var query := PhysicsRayQueryParameters3D.create(start, end, 1)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider is Interactable:
		focus = hit.collider
	hud.set_focus(focus.prompt() if is_instance_valid(focus) else "")

func try_interact() -> void:
	# Refresh before E: stale focus cannot interact through a wall or out of range.
	update_focus()
	if is_instance_valid(focus):
		focus.interact(hud)
