class_name CardPackDefinition
extends Resource
## Per-card rarity odds. Draws use replacement; duplicates are intentional.
@export var stable_id: String = ""
@export var card_set: CardSetDefinition
@export_range(1, 10) var cards_per_pack: int = 3
@export var rarity_weights: Dictionary = {}

func validation_errors(catalog: CardCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	if stable_id.strip_edges().is_empty() or not card_set or not catalog:
		errors.append("Pack ID, set and catalog are required")
		return errors
	if not catalog.sets.has(card_set) or cards_per_pack < 1 or cards_per_pack > 10:
		errors.append("Pack set must be registered and size must be 1–10")
	if rarity_weights.is_empty():
		errors.append("Pack must have rarity weights")
	var eligible := catalog.cards_for_set(card_set.stable_id)
	for id in rarity_weights:
		var weight: Variant = rarity_weights[id]
		if not (weight is float or weight is int) or not is_finite(float(weight)) or float(weight) <= 0:
			errors.append("Weights must be finite positive numbers")
		var has_card := false
		for card in eligible:
			if card.rarity and card.rarity.stable_id == id:
				has_card = true
		if not has_card:
			errors.append("Weighted rarity has no eligible cards: " + str(id))
	return errors

func draw(catalog: CardCatalog, rng: RandomNumberGenerator) -> Array[String]:
	var result: Array[String] = []
	if not catalog or not catalog.validation_errors().is_empty() or not validation_errors(catalog).is_empty():
		return result
	var total := 0.0
	var rarity_ids: Array = rarity_weights.keys()
	rarity_ids.sort()
	for id in rarity_ids:
		total += float(rarity_weights[id])
	var eligible := catalog.cards_for_set(card_set.stable_id)
	for slot in range(cards_per_pack):
		var roll := rng.randf() * total
		var chosen: String = rarity_ids.back()
		for id in rarity_ids:
			roll -= float(rarity_weights[id])
			if roll < 0:
				chosen = id
				break
		var pool: Array[CardDefinition] = []
		for card in eligible:
			if card.rarity.stable_id == chosen:
				pool.append(card)
		result.append(pool[rng.randi_range(0,pool.size()-1)].stable_id)
	return result
