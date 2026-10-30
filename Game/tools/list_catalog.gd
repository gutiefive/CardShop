extends SceneTree

func _initialize() -> void:
	var catalog: CardCatalog = load("res://data/cards/rookie_catalog.tres")
	var errors := catalog.validation_errors()
	if not errors.is_empty():
		for message in errors:
			push_error(message)
		quit(1)
		return
	for card_set in catalog.sets:
		print("%s (%s)" % [card_set.display_name,card_set.stable_id])
		for card in catalog.cards_for_set(card_set.stable_id):
			print("#%03d | %s | %s | %s | %s" % [card.card_number,card.display_name(),card.player.team_name,card.rarity.display_name,ProductDefinition.format_price(card.base_value_cents)])
	print("VALID: %d players, %d sets, %d rarities, %d cards" % [catalog.players.size(),catalog.sets.size(),catalog.rarities.size(),catalog.cards.size()])
	quit(0)
