class_name CardCollection
extends RefCounted
## Player-owned copy counts, keyed by stable card ID. No authored Resource mutation.
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

func snapshot() -> Dictionary:
	return _counts.duplicate()

func snapshot_errors(data: Variant, catalog: CardCatalog) -> PackedStringArray:
	if not data is Dictionary:
		return PackedStringArray(["Collection must be an object"])
	var errors := PackedStringArray()
	for id in data:
		if not id is String or not catalog.find_card(id) or not SaveValues.whole(data[id],1,1000000):
			errors.append("Invalid collection ID or count: " + str(id))
	return errors

func restore_snapshot(data: Dictionary, catalog: CardCatalog) -> bool:
	if not snapshot_errors(data,catalog).is_empty():
		return false
	_counts.clear()
	for id in data:
		_counts[id] = int(data[id])
	return true
