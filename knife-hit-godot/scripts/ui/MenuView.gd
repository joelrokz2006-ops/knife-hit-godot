class_name MenuView
extends Control

@onready var play_button: Button = $PlayButton
@onready var shop_button: Button = $BottomBar/ShopButton
@onready var sound_button: Button = $TopBar/SoundButton
@onready var apples_label: Label = $TopBar/ApplesContainer/ApplesLabel
@onready var highscore_label: Label = $ScoreContainer/HighScoreLabel
@onready var rotating_target: Sprite2D = $CenterShowcase/TargetSprite
@onready var showcase_knife: Sprite2D = $CenterShowcase/KnifeSprite

func _ready() -> void:
	play_button.pressed.connect(on_play_pressed)
	shop_button.pressed.connect(on_shop_pressed)
	sound_button.pressed.connect(on_sound_pressed)
	
	refresh_display()
	animate_elements()

func _process(delta: float) -> void:
	if rotating_target:
		rotating_target.rotation += 1.2 * delta

func refresh_display() -> void:
	apples_label.text = str(Save.apples)
	highscore_label.text = "BEST SCORE: %d" % Save.high_score
	
	# Update sound button modulate
	sound_button.modulate = Color.WHITE if Save.sound_enabled else Color(0.5, 0.5, 0.5, 0.6)
	
	# Update equipped knife preview
	var knife_path := "res://assets/art/knifes/%s.png" % Save.equipped_knife
	if ResourceLoader.exists(knife_path):
		showcase_knife.texture = load(knife_path)

func animate_elements() -> void:
	# Subtle pulse for the Play button
	var tw := create_tween().set_loops()
	tw.tween_property(play_button, "scale", Vector2(1.08, 1.08), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(play_button, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	
	# Gentle bobbing for knife
	var ktw := create_tween().set_loops()
	ktw.tween_property(showcase_knife, "position:y", showcase_knife.position.y - 15.0, 1.2).set_trans(Tween.TRANS_SINE)
	ktw.tween_property(showcase_knife, "position:y", showcase_knife.position.y + 15.0, 1.2).set_trans(Tween.TRANS_SINE)

func on_play_pressed() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func on_shop_pressed() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/shop/Shop.tscn")

func on_sound_pressed() -> void:
	AudioManager.play_click()
	Save.toggle_sound()
	refresh_display()
