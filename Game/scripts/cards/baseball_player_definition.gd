class_name BaseballPlayerDefinition
extends Resource
## Fictional authored identity, not a simulated season or mutable save record.
enum Position { PITCHER, CATCHER, FIRST_BASE, SECOND_BASE, THIRD_BASE, SHORTSTOP, LEFT_FIELD, CENTER_FIELD, RIGHT_FIELD }
enum Hand { LEFT, RIGHT, SWITCH }
@export var stable_id: String = ""
@export var display_name: String = ""
@export var team_name: String = ""
@export var position: Position = Position.PITCHER
@export var bats: Hand = Hand.RIGHT
@export var throws: Hand = Hand.RIGHT
@export_multiline var biography: String = ""

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if stable_id.strip_edges().is_empty() or display_name.strip_edges().is_empty():
		errors.append("Player ID and name are required")
	if team_name.strip_edges().is_empty() or biography.strip_edges().is_empty():
		errors.append("Player team and biography are required")
	if position not in Position.values() or bats not in Hand.values() or throws not in [Hand.LEFT, Hand.RIGHT]:
		errors.append("Invalid player position or handedness")
	return errors
