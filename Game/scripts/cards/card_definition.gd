class_name CardDefinition
extends Resource
## Definition of a printed card, never an owned card instance.
@export var stable_id: String = ""
@export var card_number: int = 1
@export var player: BaseballPlayerDefinition
@export var card_set: CardSetDefinition
@export var rarity: CardRarityDefinition
@export var base_value_cents: int = 0
@export_multiline var flavor_text: String = ""

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if stable_id.strip_edges().is_empty():
		errors.append("Card ID is required")
	if card_number < 1 or base_value_cents < 0:
		errors.append("Card number must be positive and value nonnegative")
	if not player or not card_set or not rarity:
		errors.append("Card player, set and rarity are required")
	return errors

func display_name() -> String:
	return player.display_name if player else "Unknown player"
