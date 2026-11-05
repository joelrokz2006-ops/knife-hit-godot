class_name StageGenerator
extends RefCounted

const STAGES_FILE := "res://data/stages.json"

static var cached_stages: Array = []

static func load_stages() -> void:
	if cached_stages.size() > 0:
		return
	if FileAccess.file_exists(STAGES_FILE):
		var file := FileAccess.open(STAGES_FILE, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			cached_stages = json.data.get("stages", [])

static func get_stage_config(stage_num: int) -> Dictionary:
	load_stages()
	# Check if handcrafted stage exists
	for s in cached_stages:
		if s.get("stage", -1) == stage_num:
			return s
	
	# Procedural generation for endless stages
	var is_boss: bool = (stage_num % 5 == 0)
	var knives_count: int = mini(14, 7 + (stage_num / 2))
	var initial_knives: Array = []
	var apples: Array = []
	
	var obstacle_count: int = mini(5, 1 + (stage_num / 3))
	if is_boss:
		obstacle_count += 1
		knives_count += 2
	
	for i in range(obstacle_count):
		initial_knives.append((TAU / obstacle_count) * i + randf_range(-0.2, 0.2))
	
	if randf() < 0.6 or is_boss:
		apples.append(randf_range(0.0, TAU))
		if is_boss:
			apples.append(randf_range(0.0, TAU))
	
	var textures: Array[String] = [
		"res://assets/art/targets/log_wood_1.png",
		"res://assets/art/targets/log_wood_2.png",
		"res://assets/art/targets/log_wood_3.png"
	]
	var boss_textures: Array[String] = [
		"res://assets/art/targets/boss_clock.png",
		"res://assets/art/targets/boss_dart_target.png",
		"res://assets/art/targets/boss_watermelon.png",
		"res://assets/art/targets/boss_pizza.png",
		"res://assets/art/targets/boss_discoball.png",
		"res://assets/art/targets/boss_skull.png",
		"res://assets/art/targets/boss_sunflower.png",
		"res://assets/art/targets/boss_wine_barrel.png"
	]
	
	var target_tex: String = boss_textures.pick_random() if is_boss else textures.pick_random()
	var boss_names: Array[String] = [
		"TITAN LOG", "CHRONO CLOCK", "IRON SKULL", "BULLSEYE", 
		"DISCO SPHERE", "SUNBURST", "PIRATE CASK", "SLICE OF PIZZA"
	]
	
	var rot_patterns: Array = [
		[
			{"duration": 1.5, "speed": randf_range(2.5, 4.2), "dir": 1, "curve": "ease"},
			{"duration": 1.5, "speed": randf_range(2.5, 4.2), "dir": -1, "curve": "ease"}
		],
		[
			{"duration": 2.0, "speed": randf_range(3.0, 5.0), "dir": 1, "curve": "sine"},
			{"duration": 0.6, "speed": 0.5, "dir": 1, "curve": "linear"}
		],
		[
			{"duration": 1.2, "speed": randf_range(3.5, 5.5), "dir": 1, "curve": "ease"},
			{"duration": 0.3, "speed": 0.0, "dir": 1, "curve": "linear"},
			{"duration": 1.2, "speed": randf_range(3.5, 5.5), "dir": -1, "curve": "ease"}
		]
	]
	
	return {
		"stage": stage_num,
		"knives": knives_count,
		"target_texture": target_tex,
		"is_boss": is_boss,
		"boss_name": boss_names.pick_random() if is_boss else "",
		"initial_knives": initial_knives,
		"apples": apples,
		"rotation": rot_patterns.pick_random()
	}
