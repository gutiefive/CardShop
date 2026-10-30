@tool
extends EditorPlugin
var confirmation: ConfirmationDialog

func _enter_tree() -> void:
	confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Replace the generated starter scene on disk? Save any custom work elsewhere first. Close/reopen the scene after generation."
	confirmation.confirmed.connect(_generate)
	add_child(confirmation)
	add_tool_menu_item("Regenerate Card Shop",_ask)

func _ask() -> void:
	confirmation.popup_centered()

func _generate() -> void:
	var error := ShopBuilder.save_scene()
	if error != OK:
		push_error(error_string(error))
	else:
		get_editor_interface().get_resource_filesystem().scan()
		print("Starter shop regenerated; reopen the scene to load changes.")

func _exit_tree() -> void:
	remove_tool_menu_item("Regenerate Card Shop")
	confirmation.queue_free()
