class_name ProductDefinition
extends Resource
## Authored data only. Stable IDs are independent of scene names or paths.
enum ProductType { BOOSTER_PACK, HOBBY_BOX }

@export var stable_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var purchase_cents: int = 0
@export var retail_cents: int = 0
@export var card_set: CardSetDefinition
@export var product_type: ProductType = ProductType.BOOSTER_PACK

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if stable_id.strip_edges().is_empty():
		errors.append("Stable ID is required")
	if display_name.strip_edges().is_empty() or description.strip_edges().is_empty():
		errors.append("Name and description are required")
	if purchase_cents < 0 or retail_cents < purchase_cents:
		errors.append("Prices must be nonnegative; retail must cover purchase")
	if product_type not in ProductType.values():
		errors.append("Unknown product type")
	if card_set:
		errors.append_array(card_set.validation_errors())
	return errors

static func format_price(cents: int) -> String:
	return "$%.2f" % (cents / 100.0)
