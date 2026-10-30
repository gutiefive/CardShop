class_name CardCollection
extends RefCounted
## Session-owned copy counts, keyed by stable card ID. No authored Resource mutation.
var _counts: Dictionary = {}

func count(id: String) -> int:
	return _counts.get(id,0)

func total_copies() -> int:
	var result := 0
	for value in _counts.values():
		result += int(value)
	return result

func unique_cards() -> int:
	return _counts.size()

func add_cards(ids: Array[String], catalog: CardCatalog) -> bool:
	# Validate the entire batch before changing any counts.
	if ids.is_empty() or not catalog:
		return false
	for id in ids:
		if not catalog.find_card(id):
			return false
	for id in ids:
		_counts[id] = count(id) + 1
	return true
