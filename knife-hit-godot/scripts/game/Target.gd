class_name Target
extends Node2D

@export var radius: float = 260.0
@export var base_speed: float = 2.0

var stuck_knife_angles: Array[float] = []
var active_apples: Array[Apple] = []

var pattern: Array = []
var current_step_idx: int = 0
var step_elapsed: float = 0.0

var current_speed: float = 2.0
var current_dir: int = 1

var is_destroyed: bool = false

@onready var sprite: Sprite2D = $TargetSprite
@onready var stuck_knives_container: Node2D = $StuckKnives
@onready var apples_container: Node2D = $Apples

const KNIFE_STUCK_SCENE := preload("res://scenes/game/StuckKnife.tscn")
const APPLE_SCENE := preload("res://scenes/game/Apple.tscn")

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
	update_rotation(delta)

func setup(config: Dictionary) -> void:
	is_destroyed = false
	stuck_knife_angles.clear()
	active_apples.clear()
	
	# Clear previous children
	for c in stuck_knives_container.get_children():
		c.queue_free()
	for c in apples_container.get_children():
		c.queue_free()
	
	# Set Texture
	var tex_path: String = config.get("target_texture", "res://assets/art/targets/log_wood_1.png")
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	
	# Scale target sprite to match radius (260px radius -> 520px diameter)
	var tex_size := sprite.texture.get_size()
	var scale_factor := (radius * 2.0) / tex_size.x
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Rotation patterns
	pattern = config.get("rotation", [{"duration": 999.0, "speed": 2.0, "dir": 1, "curve": "linear"}])
	current_step_idx = 0
	step_elapsed = 0.0
	rotation = 0.0
	
	# Spawn pre-stuck obstacle knives
	var initial_knives: Array = config.get("initial_knives", [])
	for angle in initial_knives:
		add_stuck_knife(angle, "res://assets/art/ui/knife_obstacle.png")
	
	# Spawn apples
	var apples_data: Array = config.get("apples", [])
	for a_angle in apples_data:
		add_apple(a_angle)

func update_rotation(delta: float) -> void:
	if pattern.size() == 0:
		rotation += base_speed * delta
		return
	
	var step: Dictionary = pattern[current_step_idx]
	var duration: float = step.get("duration", 2.0)
	var target_speed: float = step.get("speed", 2.0)
	var target_dir: int = step.get("dir", 1)
	var curve: String = step.get("curve", "linear")
	
	step_elapsed += delta
	if step_elapsed >= duration:
		step_elapsed = 0.0
		current_step_idx = (current_step_idx + 1) % pattern.size()
		step = pattern[current_step_idx]
	
	var t: float = clampf(step_elapsed / duration, 0.0, 1.0)
	var speed_factor: float = 1.0
	
	match curve:
		"linear":
			speed_factor = 1.0
		"ease":
			speed_factor = sin(t * PI)
		"sine":
			speed_factor = 0.5 + 0.5 * sin(t * TAU)
	
	current_speed = target_speed * speed_factor
	current_dir = target_dir
	rotation += current_speed * current_dir * delta

func add_stuck_knife(angle: float, custom_tex: String = "") -> void:
	stuck_knife_angles.append(angle)
	var knife_node: Node2D = KNIFE_STUCK_SCENE.instantiate()
	knife_node.position = Vector2(cos(angle), sin(angle)) * (radius - 5.0)
	knife_node.rotation = angle - PI / 2.0
	
	if custom_tex != "" and ResourceLoader.exists(custom_tex):
		var k_sprite: Sprite2D = knife_node.get_node_or_null("Sprite2D")
		if k_sprite:
			k_sprite.texture = load(custom_tex)
	else:
		# Use equipped knife
		var cur_tex := "res://assets/art/knifes/%s.png" % Save.equipped_knife
		if ResourceLoader.exists(cur_tex):
			var k_sprite: Sprite2D = knife_node.get_node_or_null("Sprite2D")
			if k_sprite:
				k_sprite.texture = load(cur_tex)
				
	stuck_knives_container.add_child(knife_node)

func add_apple(angle: float, golden: bool = false) -> void:
	var apple: Apple = APPLE_SCENE.instantiate()
	apples_container.add_child(apple)
	apple.setup(angle, radius + 20.0, golden)
	active_apples.append(apple)

func check_knife_collision(hit_angle: float, min_gap_rad: float) -> bool:
	# Checks if hit_angle is too close to any already stuck knife
	for angle in stuck_knife_angles:
		var diff := absf(wrapf(hit_angle - angle, -PI, PI))
		if diff < min_gap_rad:
			return true # COLLISION with another knife!
	return false

func check_apple_slice(hit_angle: float, hit_window_rad: float) -> void:
	for apple in active_apples:
		if is_instance_valid(apple) and not apple.is_sliced:
			var diff := absf(wrapf(hit_angle - apple.angle_in_target, -PI, PI))
			if diff < hit_window_rad:
				apple.slice()

func hit_effect() -> void:
	# Punchy impact bounce: jolt target upwards slightly and spring back
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - 14.0, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y, 0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func shatter() -> void:
	is_destroyed = true
	
	# Release all stuck knives to fly off dynamically with gravity and spin
	for knife in stuck_knives_container.get_children():
		var g_pos: Vector2 = knife.global_position
		var g_rot: float = knife.global_rotation
		knife.get_parent().remove_child(knife)
		get_parent().add_child(knife)
		knife.global_position = g_pos
		knife.global_rotation = g_rot
		
		# Animate flying outwards
		var fly_dir := (g_pos - global_position).normalized()
		var rand_vel := fly_dir * randf_range(400.0, 900.0) + Vector2(randf_range(-200, 200), randf_range(200, 600))
		var rand_spin := randf_range(-15.0, 15.0)
		
		var ktw := create_tween().set_parallel(true)
		ktw.tween_property(knife, "position", knife.position + rand_vel, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ktw.tween_property(knife, "rotation", knife.rotation + rand_spin, 0.8)
		ktw.tween_property(knife, "modulate:a", 0.0, 0.8)
		ktw.chain().tween_callback(knife.queue_free)
	
	# Target shrink & shatter
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "rotation", sprite.rotation + 2.0, 0.35)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.35)
