class_name GameDirector
extends Node2D

enum State { MENU, STAGE_INTRO, PLAYING, STAGE_CLEAR, GAME_OVER }

var current_state: State = State.STAGE_INTRO
var active_knife: Knife = null
var is_spawning_knife: bool = false

@onready var target: Target = $World/Target
@onready var camera: Camera2D = $Camera2D
@onready var world: Node2D = $World
@onready var hud: Hud = $HUD
@onready var game_over_view: GameOverView = $GameOverView
@onready var pause_view: PauseView = $PauseView

const KNIFE_SCENE := preload("res://scenes/game/Knife.tscn")
const SPAWN_POS := Vector2(540, 1550)

func _ready() -> void:
	EventBus.request_restart.connect(restart_game)
	EventBus.stage_cleared.connect(on_stage_cleared)
	EventBus.game_over.connect(on_game_over)
	EventBus.request_pause.connect(func(): if pause_view: pause_view.open())
	
	start_game()

func start_game() -> void:
	Game.reset_game()
	load_stage(1)

func restart_game() -> void:
	Game.reset_game()
	load_stage(1)

func load_stage(stage_num: int) -> void:
	current_state = State.STAGE_INTRO
	
	# Clear any lingering flying knives
	if is_instance_valid(active_knife):
		active_knife.queue_free()
		active_knife = null
	
	var config := StageGenerator.get_stage_config(stage_num)
	Game.setup_stage(stage_num, config.get("knives", 7), config.get("is_boss", false), config.get("boss_name", ""))
	
	# Setup target
	target.setup(config)
	
	# Target drop-in / pop-in entrance animation
	target.scale = Vector2.ZERO
	target.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(target, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(target, "modulate:a", 1.0, 0.3)
	
	tw.chain().tween_callback(func():
		current_state = State.PLAYING
		spawn_ready_knife()
	)

func spawn_ready_knife() -> void:
	if current_state != State.PLAYING:
		return
	if Game.knives_remaining <= 0:
		return
	if is_instance_valid(active_knife) and active_knife.state == Knife.State.READY:
		return
		
	active_knife = KNIFE_SCENE.instantiate()
	world.add_child(active_knife)
	active_knife.setup(target, SPAWN_POS)

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.PLAYING:
		return
		
	if event.is_action_pressed("throw"):
		throw_knife()

func throw_knife() -> void:
	if is_instance_valid(active_knife) and active_knife.state == Knife.State.READY:
		var k := active_knife
		active_knife = null
		k.launch()
		
		# Schedule spawn of next knife after a brief moment
		if Game.knives_remaining > 1:
			var tw := create_tween()
			tw.tween_interval(0.12)
			tw.chain().tween_callback(spawn_ready_knife)

func on_stage_cleared(_cleared_stage: int) -> void:
	current_state = State.STAGE_CLEAR
	
	# Wait for shatter animation and proceed to next stage
	var tw := create_tween()
	tw.tween_interval(0.85)
	tw.chain().tween_callback(func():
		load_stage(Game.stage + 1)
	)

func on_game_over(_stage_num: int, _score: int) -> void:
	current_state = State.GAME_OVER
