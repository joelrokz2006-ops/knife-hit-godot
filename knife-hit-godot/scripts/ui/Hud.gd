class_name Hud
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var stage_label: Label = $StageLabel
@onready var apples_label: Label = $ApplesContainer/ApplesLabel
@onready var stage_banner: Label = $StageBanner
@onready var pause_button: Button = $PauseButton

func _ready() -> void:
	if pause_button:
		pause_button.pressed.connect(func(): EventBus.request_pause.emit())
	EventBus.score_changed.connect(on_score_changed)
	EventBus.apples_changed.connect(on_apples_changed)
	EventBus.stage_started.connect(on_stage_started)
	
	score_label.text = str(Game.score)
	apples_label.text = str(Save.apples)
	stage_banner.visible = false

func on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)
	
	# Score pop animation
	var tw := create_tween()
	score_label.scale = Vector2(1.25, 1.25)
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func on_apples_changed(total: int) -> void:
	apples_label.text = str(total)

func on_stage_started(stage_num: int, is_boss: bool, boss_name: String) -> void:
	if is_boss:
		stage_label.text = "BOSS: " + boss_name
		stage_label.modulate = Color(1.0, 0.25, 0.25)
		stage_banner.text = "BOSS FIGHT!\n" + boss_name
		stage_banner.modulate = Color(1.0, 0.2, 0.2)
	else:
		stage_label.text = "STAGE " + str(stage_num)
		stage_label.modulate = Color(1.0, 0.85, 0.5)
		stage_banner.text = "STAGE " + str(stage_num)
		stage_banner.modulate = Color(1.0, 1.0, 1.0)
	
	# Play banner entrance and exit
	stage_banner.visible = true
	stage_banner.scale = Vector2(0.5, 0.5)
	stage_banner.modulate.a = 0.0
	
	var tw := create_tween()
	tw.tween_property(stage_banner, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(stage_banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.4)
	tw.tween_property(stage_banner, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(func(): stage_banner.visible = false)
