class_name SaveValues
extends RefCounted
## JSON numbers are floats on load. Validate exact, bounded integers before conversion.
static func whole(value: Variant, minimum: int = 0, maximum: int = 2000000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum

static func int_string(value: Variant) -> bool:
	if not value is String or value.length() > 20 or not value.is_valid_int():
		return false
	return str(int(value)) == value
