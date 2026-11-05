extends Node

const SAVE_PATH := "user://save.json"

var high_score: int = 0
var apples: int = 0
var equipped_knife: String = "knife_0"
var unlocked_knives: Array = ["knife_0"]
var sound_enabled: bool = true

func _ready() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_str := file.get_as_text()
	var test_json_conv := JSON.new()
	var parse_err := test_json_conv.parse(json_str)
	if parse_err != OK:
		return
	var data: Dictionary = test_json_conv.data
	high_score = data.get("high_score", 0)
	apples = data.get("apples", 0)
	equipped_knife = data.get("equipped_knife", "knife_0")
	unlocked_knives = data.get("unlocked_knives", ["knife_0"])
	sound_enabled = data.get("sound_enabled", true)

func save_data() -> void:
	var data := {
		"high_score": high_score,
		"apples": apples,
		"equipped_knife": equipped_knife,
		"unlocked_knives": unlocked_knives,
		"sound_enabled": sound_enabled
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func add_apples(amount: int) -> void:
	apples += amount
	EventBus.apples_changed.emit(apples)
	save_data()

func update_high_score(score: int) -> bool:
	if score > high_score:
		high_score = score
		save_data()
		return true
	return false

func toggle_sound() -> bool:
	sound_enabled = not sound_enabled
	save_data()
	return sound_enabled

func can_afford(cost: int) -> bool:
	return apples >= cost

func purchase_knife(knife_id: String, cost: int) -> bool:
	if is_knife_unlocked(knife_id):
		equip_knife(knife_id)
		return true
	if can_afford(cost):
		add_apples(-cost)
		unlock_knife(knife_id)
		equip_knife(knife_id)
		return true
	return false

func is_knife_unlocked(knife_id: String) -> bool:
	return knife_id in unlocked_knives

func unlock_knife(knife_id: String) -> void:
	if not knife_id in unlocked_knives:
		unlocked_knives.append(knife_id)
		save_data()

func equip_knife(knife_id: String) -> void:
	if is_knife_unlocked(knife_id):
		equipped_knife = knife_id
		EventBus.skin_changed.emit(equipped_knife)
		save_data()
