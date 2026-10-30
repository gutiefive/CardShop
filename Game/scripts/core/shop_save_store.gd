class_name ShopSaveStore
extends RefCounted
## Plain JSON, validated before mutation. Temporary write + prior valid checkpoint backup.
const VERSION := 1
var path: String
var error: String = ""
var loaded_backup: bool = false

func _init(save_path: String = "user://shop_save_v1.json") -> void:
	path = save_path

func exists() -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak")

func read_valid(file_path: String, retail: RetailSession, packs: PackSession) -> Dictionary:
	var file := FileAccess.open(file_path,FileAccess.READ)
	if not file or file.get_length() > 4194304:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	if not SaveValues.whole(data.get("version"),VERSION,VERSION):
		return {}
	if not retail.snapshot_errors(data.get("retail")).is_empty() or not packs.snapshot_errors(data.get("packs")).is_empty():
		return {}
	return data

func load_into(retail: RetailSession, packs: PackSession) -> bool:
	error = ""
	loaded_backup = false
	var data := read_valid(path,retail,packs)
	if data.is_empty():
		data = read_valid(path+".bak",retail,packs)
		loaded_backup = not data.is_empty()
	if data.is_empty():
		error = "Save or backup is invalid/unsupported" if exists() else "No saved shop yet"
		return false
	# Both sections have already passed validation; no partial restore on errors.
	retail.restore_snapshot(data.retail)
	packs.restore_snapshot(data.packs)
	return true

func save(retail: RetailSession, packs: PackSession) -> bool:
	error = ""
	var data := {"version":VERSION,"retail":retail.snapshot(),"packs":packs.snapshot()}
	if not retail.snapshot_errors(data.retail).is_empty() or not packs.snapshot_errors(data.packs).is_empty():
		error = "Live shop state failed save validation"
		return false
	var temp := path+".tmp"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if not file:
		error = "Cannot write save file: " + error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data,"\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error = "Save write failed: " + error_string(write_error)
		return false
	# Do not replace a good backup with a corrupt primary.
	if not read_valid(path,retail,packs).is_empty():
		var copy_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".bak"))
		if copy_error != OK:
			error = "Save backup failed: " + error_string(copy_error)
			return false
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(path))
	if result != OK:
		error = "Save replacement failed: " + error_string(result)
		return false
	return true

func archive() -> bool:
	error = ""
	var suffix := ".archived_"+str(Time.get_unix_time_from_system()).replace(".","_")+"_"+str(Time.get_ticks_usec())
	for file_path in [path,path+".bak"]:
		if FileAccess.file_exists(file_path):
			var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(file_path),ProjectSettings.globalize_path(file_path+suffix))
			if result != OK:
				error = "Could not archive previous shop: " + error_string(result)
				return false
	return true
