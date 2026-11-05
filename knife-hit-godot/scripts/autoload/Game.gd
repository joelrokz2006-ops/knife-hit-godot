extends Node

var score: int = 0
var stage: int = 1
var knives_remaining: int = 0
var knives_total: int = 0
var is_boss_stage: bool = false
var boss_name: String = ""

var balance: Dictionary = {}

func _ready() -> void:
	load_balance()

func load_balance() -> void:
	var path := "res://data/balance.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			balance = json.data

func reset_game() -> void:
	score = 0
	stage = 1
	EventBus.score_changed.emit(score)

func add_score(amount: int = 1) -> void:
	score += amount
	EventBus.score_changed.emit(score)

func setup_stage(stage_num: int, total_knives: int, boss: bool = false, b_name: String = "") -> void:
	stage = stage_num
	knives_total = total_knives
	knives_remaining = total_knives
	is_boss_stage = boss
	boss_name = b_name
	EventBus.knives_count_changed.emit(knives_remaining, knives_total)
	EventBus.stage_started.emit(stage, is_boss_stage, boss_name)

func decrement_knife() -> int:
	knives_remaining = maxi(0, knives_remaining - 1)
	EventBus.knives_count_changed.emit(knives_remaining, knives_total)
	return knives_remaining
