class_name CardSetDefinition
extends Resource
@export var stable_id: String = ""
@export var display_name: String = ""
@export var season_year: int = 2026
@export var expected_card_count: int = 0
@export_multiline var description: String = ""

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if stable_id.strip_edges().is_empty() or display_name.strip_edges().is_empty() or description.strip_edges().is_empty():
		errors.append("Set ID, name and description are required")
	if season_year < 1 or expected_card_count < 1:
		errors.append("Set year and expected card count must be positive")
	return errors
