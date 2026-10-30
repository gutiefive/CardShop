class_name PackSession
extends RefCounted
## Personal pack opening; stock/cash transactions are coordinated by the HUD.
var collection := CardCollection.new()
var starter_packs_remaining: int = 3
var catalog: CardCatalog
var rng := RandomNumberGenerator.new()

func _init(database: CardCatalog = null) -> void:
	catalog = database
	rng.randomize()

func open_pack(product: ProductDefinition, use_starter: bool = true) -> Array[String]:
	var empty: Array[String] = []
	if (use_starter and starter_packs_remaining <= 0) or not product or not product.pack_definition:
		return empty
	if product.product_type != ProductDefinition.ProductType.BOOSTER_PACK or product.card_set != product.pack_definition.card_set:
		return empty
	var cards := product.pack_definition.draw(catalog,rng)
	if cards.is_empty() or not collection.add_cards(cards,catalog):
		return empty
	if use_starter:
		starter_packs_remaining -= 1
	return cards

func snapshot() -> Dictionary:
	# Strings preserve 64-bit RNG values exactly through JSON floating-point numbers.
	return {"starter_packs":starter_packs_remaining,"collection":collection.snapshot(),"rng_seed":str(rng.seed),"rng_state":str(rng.state)}

func snapshot_errors(data: Variant) -> PackedStringArray:
	if not data is Dictionary:
		return PackedStringArray(["Personal pack save must be an object"])
	var errors := collection.snapshot_errors(data.get("collection"),catalog)
	if not SaveValues.whole(data.get("starter_packs"),0,3):
		errors.append("Invalid starter pack count")
	if not SaveValues.int_string(data.get("rng_seed")) or not SaveValues.int_string(data.get("rng_state")):
		errors.append("Invalid RNG state")
	return errors

func restore_snapshot(data: Dictionary) -> bool:
	if not snapshot_errors(data).is_empty():
		return false
	starter_packs_remaining = int(data.starter_packs)
	collection.restore_snapshot(data.collection,catalog)
	rng.seed = int(data.rng_seed)
	rng.state = int(data.rng_state)
	return true
