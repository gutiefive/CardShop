class_name CardCatalog
extends Resource
## Small authored database. Query on demand so Inspector edits cannot stale a cache.
@export var players: Array[BaseballPlayerDefinition] = []
@export var sets: Array[CardSetDefinition] = []
@export var rarities: Array[CardRarityDefinition] = []
@export var cards: Array[CardDefinition] = []

func find_card(id: String) -> CardDefinition:
	for card in cards:
		if card and card.stable_id == id:
			return card
	return null

func cards_for_set(id: String) -> Array[CardDefinition]:
	var result: Array[CardDefinition] = []
	for card in cards:
		if card and card.card_set and card.card_set.stable_id == id:
			result.append(card)
	result.sort_custom(func(a: CardDefinition, b: CardDefinition) -> bool: return a.card_number < b.card_number)
	return result

func cards_for_player(id: String) -> Array[CardDefinition]:
	var result: Array[CardDefinition] = []
	for card in cards:
		if card and card.player and card.player.stable_id == id:
			result.append(card)
	return result

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	for group in [players, sets, rarities, cards]:
		if group.is_empty():
			errors.append("Catalog groups must not be empty")
		for definition in group:
			if definition == null:
				errors.append("Null definition in catalog")
				continue
			for message in definition.validation_errors():
				errors.append(definition.stable_id + ": " + message)
			if ids.has(definition.stable_id):
				errors.append("Duplicate stable ID: " + definition.stable_id)
			ids[definition.stable_id] = true
	var numbers: Dictionary = {}
	for card in cards:
		if not card:
			continue
		if not players.has(card.player) or not sets.has(card.card_set) or not rarities.has(card.rarity):
			errors.append(card.stable_id + ": reference is not registered in catalog")
		if card.card_set:
			var key := card.card_set.stable_id + ":" + str(card.card_number)
			if numbers.has(key):
				errors.append("Duplicate card number in set: " + key)
			numbers[key] = true
			if card.card_number > card.card_set.expected_card_count:
				errors.append(card.stable_id + ": number exceeds set size")
	for card_set in sets:
		if card_set and cards_for_set(card_set.stable_id).size() != card_set.expected_card_count:
			errors.append(card_set.stable_id + ": card count does not match set checklist")
	return errors
