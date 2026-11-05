class_name GameOverView
extends CanvasLayer

@onready var panel: Control = $Panel
@onready var score_val: Label = $Panel/VBoxContainer/ScoreVal
@onready var stage_val: Label = $Panel/VBoxContainer/StageVal
@onready var best_val: Label = $Panel/VBoxContainer/BestVal
@onready var new_best_label: Label = $Panel/VBoxContainer/NewBestLabel
@onready var restart_btn: Button = $Panel/VBoxContainer/ButtonsContainer/RestartButton
@onready var home_btn: Button = $Panel/VBoxContainer/ButtonsContainer/HomeButton
@onready var shop_btn: Button = $Panel/VBoxContainer/ButtonsContainer/ShopButton

func _ready() -> void:
	visible = false
	EventBus.game_over.connect(show_game_over)
	restart_btn.pressed.connect(on_restart_pressed)
	if home_btn:
		home_btn.pressed.connect(on_home_pressed)
	if shop_btn:
		shop_btn.pressed.connect(on_shop_pressed)

func show_game_over(stage_num: int, final_score: int) -> void:
	var is_new_best: bool = Save.update_high_score(final_score)
	
	stage_val.text = "STAGE %d" % stage_num
	score_val.text = "%d" % final_score
	best_val.text = "BEST: %d" % Save.high_score
	new_best_label.visible = is_new_best
	
	visible = true
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)

func on_restart_pressed() -> void:
	AudioManager.play_click()
	visible = false
	EventBus.request_restart.emit()

func on_home_pressed() -> void:
	AudioManager.play_click()
	visible = false
	get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")

func on_shop_pressed() -> void:
	AudioManager.play_click()
	visible = false
	get_tree().change_scene_to_file("res://scenes/shop/Shop.tscn")
