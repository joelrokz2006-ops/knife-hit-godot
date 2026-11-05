class_name Knife
extends Node2D

enum State { READY, FLYING, STUCK, BOUNCING }

@export var fly_speed: float = 3600.0
@export var min_gap_rad: float = 0.22

var state: State = State.READY
var velocity: Vector2 = Vector2.ZERO
var bounce_angular_velocity: float = 0.0
var gravity: float = 3800.0

@onready var sprite: Sprite2D = $Sprite2D

var target_node: Target = null

func _ready() -> void:
	refresh_skin()
	EventBus.skin_changed.connect(func(_k): refresh_skin())

func refresh_skin() -> void:
	var skin_path := "res://assets/art/knifes/%s.png" % Save.equipped_knife
	if ResourceLoader.exists(skin_path):
		sprite.texture = load(skin_path)

func setup(t: Target, spawn_pos: Vector2 = Vector2(540, 1550)) -> void:
	target_node = t
	global_position = spawn_pos
	rotation = 0.0
	state = State.READY
	visible = true
	scale = Vector2(0.9, 0.9)
	
	# Spawn scale pop
	var tw := create_tween()
	scale = Vector2(0.3, 0.3)
	tw.tween_property(self, "scale", Vector2(0.9, 0.9), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func launch() -> void:
	if state != State.READY:
		return
	state = State.FLYING
	velocity = Vector2.UP * fly_speed
	EventBus.knife_thrown.emit()

func _physics_process(delta: float) -> void:
	match state:
		State.FLYING:
			position += velocity * delta
			if target_node and is_instance_valid(target_node):
				check_target_impact()
				
		State.BOUNCING:
			velocity.y += gravity * delta
			position += velocity * delta
			rotation += bounce_angular_velocity * delta
			if position.y > 2100:
				queue_free()

func check_target_impact() -> void:
	var dist := global_position.distance_to(target_node.global_position)
	if dist <= target_node.radius:
		resolve_impact()

func resolve_impact() -> void:
	# Calculate impact position on target's surface
	var diff_to_center := global_position - target_node.global_position
	var hit_angle_world := atan2(diff_to_center.y, diff_to_center.x)
	var hit_angle_local := wrapf(hit_angle_world - target_node.rotation, -PI, PI)
	
	# Check apple collection
	target_node.check_apple_slice(hit_angle_local, 0.35)
	
	# Check collision with already stuck knives
	var collides := target_node.check_knife_collision(hit_angle_local, min_gap_rad)
	if collides:
		# FAILURE: Hit another knife!
		state = State.BOUNCING
		EventBus.knife_hit_knife.emit(global_position)
		
		# Ricochet bounce physics
		velocity = Vector2(randf_range(-300.0, 300.0), 400.0)
		bounce_angular_velocity = randf_range(-18.0, 18.0)
		
		# Signal Game Over
		EventBus.game_over.emit(Game.stage, Game.score)
	else:
		# SUCCESS: Stuck to target
		state = State.STUCK
		target_node.add_stuck_knife(hit_angle_local)
		target_node.hit_effect()
		EventBus.knife_hit_target.emit(global_position, hit_angle_local)
		
		Game.add_score(1)
		var remaining := Game.decrement_knife()
		
		if remaining == 0:
			target_node.shatter()
			EventBus.stage_cleared.emit(Game.stage)
			
		queue_free()
