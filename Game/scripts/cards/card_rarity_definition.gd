class_name CardRarityDefinition
extends Resource
## Presentation metadata only; pack odds belong to a later milestone.
@export var stable_id: String = ""
@export var display_name: String = ""
@export var accent_color: Color = Color.WHITE
@export var sort_order: int = 0

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if stable_id.strip_edges().is_empty() or display_name.strip_edges().is_empty():
		errors.append("Rarity ID and name are required")
	if sort_order < 0:
		errors.append("Rarity sort order must be nonnegative")
	return errors
