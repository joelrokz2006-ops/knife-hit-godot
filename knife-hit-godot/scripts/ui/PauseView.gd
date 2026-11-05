class_name PauseView
extends CanvasLayer

@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $Panel/VBoxContainer/RestartButton
@onready var home_btn: Button = $Panel/VBoxContainer/HomeButton
@onready var sound_btn: Button = $Panel/VBoxContainer/SoundButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_btn.pressed.connect(on_resume_pressed)
	restart_btn.pressed.connect(on_restart_pressed)
	home_btn.pressed.connect(on_home_pressed)
	sound_btn.pressed.connect(on_sound_pressed)

func open() -> void:
	AudioManager.play_click()
	visible = true
	get_tree().paused = true
	update_sound_button()

func close() -> void:
	visible = false
	get_tree().paused = false

func on_resume_pressed() -> void:
	AudioManager.play_click()
	close()

func on_restart_pressed() -> void:
	AudioManager.play_click()
	close()
	EventBus.request_restart.emit()

func on_home_pressed() -> void:
	AudioManager.play_click()
	close()
	get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")

func on_sound_pressed() -> void:
	AudioManager.play_click()
	Save.toggle_sound()
	update_sound_button()

func update_sound_button() -> void:
	sound_btn.text = "SOUND: ON" if Save.sound_enabled else "SOUND: OFF"
	sound_btn.modulate = Color(0.3, 1.0, 0.4) if Save.sound_enabled else Color(0.8, 0.4, 0.4)
