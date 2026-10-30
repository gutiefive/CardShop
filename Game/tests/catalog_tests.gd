class_name CatalogTests
extends RefCounted

static func fresh() -> CardCatalog:
	# Clone the whole graph, including shared external .tres dependencies.
	var source: CardCatalog = load("res://data/cards/rookie_catalog.tres")
	return source.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as CardCatalog

static func run(check: Callable) -> void:
	var catalog := fresh()
	check.call(catalog.validation_errors().is_empty(),"M2 authored catalog has no validation errors")
	check.call(catalog.players.size() == 8 and catalog.cards.size() == 8 and catalog.rarities.size() == 3,"M2 has eight players/cards and three rarities")
	check.call(catalog.find_card("card-rookie-2026-001").player.display_name == "Milo Reyes","Stable card ID resolves fictional player")
	check.call(catalog.find_card("missing") == null,"Unknown card lookup returns null")
	var checklist := catalog.cards_for_set("set-rookie-2026")
	check.call(checklist.size() == 8 and checklist[0].card_number == 1 and checklist[7].card_number == 8,"Set query produces numbered checklist")
	check.call(catalog.cards_for_set("missing").is_empty(),"Unknown set returns empty checklist")
	check.call(catalog.cards_for_player("player-asher-vale").size() == 1,"Player query resolves authored cards")
	check.call(catalog.cards_for_player("missing").is_empty(),"Unknown player query is empty")
	var pack: ProductDefinition = load("res://data/rookie_pack.tres")
	var box: ProductDefinition = load("res://data/rookie_box.tres")
	check.call(pack.card_set == box.card_set and pack.card_set.stable_id == checklist[0].card_set.stable_id,"Both products reference the Rookie Series set")
	catalog.cards[1].stable_id = catalog.cards[0].stable_id
	check.call(not catalog.validation_errors().is_empty(),"Duplicate card stable ID rejected")
	catalog = fresh()
	catalog.players[0].stable_id = catalog.rarities[0].stable_id
	check.call(not catalog.validation_errors().is_empty(),"Cross-type ID collision rejected")
	catalog = fresh()
	catalog.cards[1].card_number = catalog.cards[0].card_number
	check.call(not catalog.validation_errors().is_empty(),"Duplicate printed number within set rejected")
	catalog = fresh()
	catalog.cards[0].card_number = 9
	check.call(not catalog.validation_errors().is_empty(),"Printed card number beyond set size rejected")
	catalog = fresh()
	catalog.cards.pop_back()
	check.call(not catalog.validation_errors().is_empty(),"Incomplete set checklist rejected")
	catalog = fresh()
	catalog.cards[0].base_value_cents = -1
	check.call(not catalog.validation_errors().is_empty(),"Negative card base value rejected")
	catalog = fresh()
	catalog.cards[0].player = null
	check.call(not catalog.validation_errors().is_empty(),"Missing card player reference rejected without crashing")
	catalog = fresh()
	catalog.cards[0].rarity = catalog.rarities[0].duplicate() as CardRarityDefinition
	check.call(not catalog.validation_errors().is_empty(),"Unregistered shadow rarity rejected even with matching ID")
	catalog = fresh()
	catalog.players[0].throws = BaseballPlayerDefinition.Hand.SWITCH
	check.call(not catalog.validation_errors().is_empty(),"Invalid throwing handedness rejected")
	catalog = fresh()
	catalog.cards.append(null)
	check.call(not catalog.validation_errors().is_empty(),"Null catalog entries rejected without crashing")
	catalog = fresh()
	catalog.sets.clear()
	check.call(not catalog.validation_errors().is_empty(),"Empty catalog group and unregistered set rejected")
	catalog = fresh()
	catalog.players[0].biography = " "
	check.call(not catalog.validation_errors().is_empty(),"Blank player biography rejected")
	var authored: CardCatalog = load("res://data/cards/rookie_catalog.tres")
	check.call(authored.validation_errors().is_empty(),"Invalid fixtures leave authored resources unchanged")
