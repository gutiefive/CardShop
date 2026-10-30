class_name PackSession
extends RefCounted
## Finite free starter inventory for M3; purchasing and persistence come later.
var collection := CardCollection.new()
var starter_packs_remaining: int = 3
var catalog: CardCatalog
var rng := RandomNumberGenerator.new()

func _init(database: CardCatalog = null) -> void:
	catalog = database
	rng.randomize()

func open_pack(product: ProductDefinition) -> Array[String]:
	var empty: Array[String] = []
	if starter_packs_remaining <= 0 or not product or not product.pack_definition:
		return empty
	if product.product_type != ProductDefinition.ProductType.BOOSTER_PACK or product.card_set != product.pack_definition.card_set:
		return empty
	var cards := product.pack_definition.draw(catalog,rng)
	if cards.is_empty() or not collection.add_cards(cards,catalog):
		return empty
	starter_packs_remaining -= 1
	return cards
