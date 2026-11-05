class_name Apple
extends Node2D

@export var is_golden: bool = false
var angle_in_target: float = 0.0
var distance_from_center: float = 275.0
var is_sliced: bool = false

@onready var whole_sprite: Sprite2D = $WholeSprite
@onready var half_1: Sprite2D = $Half1
@onready var half_2: Sprite2D = $Half2

func _ready() -> void:
	half_1.visible = false
	half_2.visible = false
	whole_sprite.visible = true

func setup(ang: float, dist: float = 275.0, golden: bool = false) -> void:
	angle_in_target = ang
	distance_from_center = dist
	is_golden = golden
	rotation = ang + PI / 2.0
	position = Vector2(cos(ang), sin(ang)) * dist
	
	if is_golden:
		whole_sprite.texture = load("res://assets/art/ui/golden_apple.png")
		half_1.texture = load("res://assets/art/ui/golden_half1.png")
		half_2.texture = load("res://assets/art/ui/golden_half2.png")

func slice() -> void:
	if is_sliced:
		return
	is_sliced = true
	
	whole_sprite.visible = false
	half_1.visible = true
	half_2.visible = true
	
	EventBus.apple_collected.emit(global_position)
	Save.add_apples(2 if is_golden else 1)
	
	# Flying slice animation
	var tw := create_tween().set_parallel(true)
	tw.tween_property(half_1, "position", half_1.position + Vector2(-60, 120), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(half_1, "rotation", half_1.rotation - 1.5, 0.5)
	tw.tween_property(half_1, "modulate:a", 0.0, 0.5)
	
	tw.tween_property(half_2, "position", half_2.position + Vector2(60, 120), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(half_2, "rotation", half_2.rotation + 1.5, 0.5)
	tw.tween_property(half_2, "modulate:a", 0.0, 0.5)
	
	tw.chain().tween_callback(queue_free)
