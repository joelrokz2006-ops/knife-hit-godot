class_name HitFX
extends Node2D

@export var camera: Camera2D

var trauma: float = 0.0
const TRAUMA_DECAY: float = 2.5
const MAX_OFFSET: float = 28.0

@onready var spark_particles: CPUParticles2D = $SparkParticles
@onready var apple_particles: CPUParticles2D = $AppleParticles

func _ready() -> void:
	EventBus.knife_hit_target.connect(func(pos, _ang): on_wood_hit(pos))
	EventBus.knife_hit_knife.connect(func(pos): on_knife_hit_knife(pos))
	EventBus.apple_collected.connect(func(pos): on_apple_sliced(pos))
	EventBus.stage_cleared.connect(func(_s): on_stage_cleared())

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - TRAUMA_DECAY * delta)
		if camera:
			var shake := trauma * trauma
			camera.offset = Vector2(
				randf_range(-MAX_OFFSET, MAX_OFFSET) * shake,
				randf_range(-MAX_OFFSET, MAX_OFFSET) * shake
			)
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func on_wood_hit(pos: Vector2) -> void:
	add_trauma(0.12)
	spark_particles.global_position = pos
	spark_particles.color = Color(0.9, 0.75, 0.45) # Wood splinter color
	spark_particles.restart()

func on_knife_hit_knife(pos: Vector2) -> void:
	add_trauma(0.7)
	spark_particles.global_position = pos
	spark_particles.color = Color(1.0, 0.9, 0.3) # Bright metal sparks
	spark_particles.amount = 35
	spark_particles.restart()
	
	# Slow motion juice
	Engine.time_scale = 0.25
	var tw := create_tween()
	tw.tween_interval(0.35 * 0.25)
	tw.chain().tween_callback(func(): Engine.time_scale = 1.0)

func on_apple_sliced(pos: Vector2) -> void:
	add_trauma(0.18)
	apple_particles.global_position = pos
	apple_particles.restart()
	
	# Spawn floating +1 label
	spawn_floating_text(pos, "+1", Color(1.0, 0.3, 0.3))

func on_stage_cleared() -> void:
	add_trauma(0.4)

func spawn_floating_text(pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.global_position = pos + Vector2(-20, -30)
	label.add_theme_font_size_override("font_size", 42)
	add_child(label)
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 70.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(label.queue_free)
