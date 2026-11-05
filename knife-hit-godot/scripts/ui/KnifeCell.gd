class_name KnifeCell
extends Control

signal cell_clicked(knife_data: Dictionary)

var knife_data: Dictionary = {}

@onready var frame_rect: TextureRect = $Frame
@onready var knife_texture_rect: TextureRect = $KnifeTexture
@onready var lock_icon: TextureRect = $LockIcon
@onready var status_label: Label = $StatusLabel
@onready var select_border: ReferenceRect = $SelectBorder
@onready var button: Button = $ClickButton

func setup(data: Dictionary) -> void:
	knife_data = data
	update_state()

func _ready() -> void:
	button.pressed.connect(on_pressed)

func update_state() -> void:
	var kid: String = knife_data.get("id", "")
	var sprite_path: String = knife_data.get("sprite", "")
	var price: int = knife_data.get("price", 0)
	
	if ResourceLoader.exists(sprite_path):
		knife_texture_rect.texture = load(sprite_path)
	
	var is_unlocked: bool = Save.is_knife_unlocked(kid)
	var is_equipped: bool = (Save.equipped_knife == kid)
	
	if is_equipped:
		lock_icon.visible = false
		knife_texture_rect.modulate = Color.WHITE
		select_border.visible = true
		select_border.border_color = Color(0.2, 0.9, 0.4, 0.9)
		status_label.text = "EQUIPPED"
		status_label.modulate = Color(0.3, 1.0, 0.4)
	elif is_unlocked:
		lock_icon.visible = false
		knife_texture_rect.modulate = Color.WHITE
		select_border.visible = false
		status_label.text = "EQUIP"
		status_label.modulate = Color(0.85, 0.85, 0.9)
	else:
		lock_icon.visible = true
		knife_texture_rect.modulate = Color(0.15, 0.15, 0.2, 0.6)
		select_border.visible = false
		status_label.text = "%d 🍎" % price
		status_label.modulate = Color(1.0, 0.4, 0.4) if not Save.can_afford(price) else Color(1.0, 0.9, 0.3)

func on_pressed() -> void:
	AudioManager.play_click()
	cell_clicked.emit(knife_data)

func shake() -> void:
	var tw := create_tween()
	var orig_x := position.x
	tw.tween_property(self, "position:x", orig_x - 10.0, 0.04)
	tw.tween_property(self, "position:x", orig_x + 10.0, 0.04)
	tw.tween_property(self, "position:x", orig_x - 6.0, 0.04)
	tw.tween_property(self, "position:x", orig_x, 0.04)
