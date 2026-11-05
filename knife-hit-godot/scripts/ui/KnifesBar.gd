class_name KnifesBar
extends VBoxContainer

const KNIFE_ICON_PATH := "res://assets/art/ui/knife_icon.png"

var knife_icons: Array[TextureRect] = []

func _ready() -> void:
	EventBus.knives_count_changed.connect(update_icons)

func update_icons(remaining: int, total: int) -> void:
	# Rebuild icons if total count changed
	if knife_icons.size() != total:
		for c in get_children():
			c.queue_free()
		knife_icons.clear()
		
		var icon_tex := load(KNIFE_ICON_PATH) as Texture2D
		for i in range(total):
			var tr := TextureRect.new()
			tr.texture = icon_tex
			tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tr.custom_minimum_size = Vector2(36, 64)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			add_child(tr)
			knife_icons.append(tr)
	
	# Update modulate colors
	for i in range(knife_icons.size()):
		var tr: TextureRect = knife_icons[i]
		if i < remaining:
			tr.modulate = Color(1.0, 0.5, 0.1) # Bright active orange/gold
		else:
			tr.modulate = Color(0.2, 0.2, 0.25, 0.4) # Dark consumed
