class_name ShopManager
extends RefCounted

const KNIVES_PATH := "res://data/knives.json"
const RANDOM_UNLOCK_COST := 500

static var _cached_knives: Array = []

static func get_all_knives() -> Array:
	if _cached_knives.size() == 0:
		load_knives()
	return _cached_knives

static func load_knives() -> void:
	if FileAccess.file_exists(KNIVES_PATH):
		var file := FileAccess.open(KNIVES_PATH, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_cached_knives = json.data.get("knives", [])

static func get_knife_by_id(knife_id: String) -> Dictionary:
	var knives := get_all_knives()
	for k in knives:
		if k.get("id", "") == knife_id:
			return k
	return {}

static func get_unlocked_count() -> int:
	var count := 0
	var knives := get_all_knives()
	for k in knives:
		if Save.is_knife_unlocked(k.get("id", "")):
			count += 1
	return count

static func get_total_count() -> int:
	return get_all_knives().size()

static func unlock_random_knife() -> Dictionary:
	if not Save.can_afford(RANDOM_UNLOCK_COST):
		return {}
	
	var locked: Array = []
	for k in get_all_knives():
		var kid: String = k.get("id", "")
		if not Save.is_knife_unlocked(kid):
			locked.append(k)
	
	if locked.size() == 0:
		return {}
	
	var chosen: Dictionary = locked.pick_random()
	var kid: String = chosen.get("id", "")
	Save.purchase_knife(kid, RANDOM_UNLOCK_COST)
	return chosen
