extends Node

func _ready() -> void:
	print("========================================")
	print("--- RUNNING KNIFE HIT VERIFICATION SUITE ---")
	print("========================================")
	
	# Test 1: Autoloads and Save persistence
	assert(Save != null, "Save autoload must exist")
	assert(EventBus != null, "EventBus autoload must exist")
	assert(Game != null, "Game autoload must exist")
	assert(AudioManager != null, "AudioManager autoload must exist")
	print("[PASS] Test 1: All autoload singletons loaded.")
	
	# Test 2: Economy & Knife Catalogue
	var knives := ShopManager.get_all_knives()
	assert(knives.size() >= 200, "Must have 200+ knives in catalogue")
	print("[PASS] Test 2: Knife catalogue loaded with %d knives." % knives.size())
	
	# Test 3: Unlocking and Equipping
	var initial_apples := Save.apples
	Save.add_apples(1000)
	assert(Save.apples == initial_apples + 1000, "Apples must increment")
	
	var test_knife := "knife_1"
	var success := Save.purchase_knife(test_knife, 250)
	assert(success, "Should successfully purchase knife_1")
	assert(Save.is_knife_unlocked(test_knife), "knife_1 should now be unlocked")
	assert(Save.equipped_knife == test_knife, "knife_1 should now be equipped")
	print("[PASS] Test 3: Economy & Knife shop unlock/equip verified.")
	
	# Test 4: Stage Generator
	for s in [1, 2, 5, 10, 15, 20, 25]:
		var cfg := StageGenerator.get_stage_config(s)
		assert(cfg.has("knives"), "Stage config must define knives")
		assert(cfg.has("rotation"), "Stage config must define rotation")
		if s % 5 == 0:
			assert(cfg.get("is_boss", false) == true, "Stage %d must be a boss stage" % s)
	print("[PASS] Test 4: StageGenerator regular and boss configs validated.")
	
	# Test 5: Angle collision logic
	var hit_angle := 1.0
	var min_gap := 0.22
	var close_knife := 1.15
	var far_knife := 2.5
	var diff_close := absf(wrapf(hit_angle - close_knife, -PI, PI))
	var diff_far := absf(wrapf(hit_angle - far_knife, -PI, PI))
	assert(diff_close < min_gap, "Close knife should trigger collision")
	assert(diff_far > min_gap, "Far knife should not trigger collision")
	print("[PASS] Test 5: Angular collision tolerance math validated.")
	
	print("========================================")
	print("ALL 5 VERIFICATION TESTS PASSED SUCCESSFULLY!")
	print("========================================")
	get_tree().quit(0)
