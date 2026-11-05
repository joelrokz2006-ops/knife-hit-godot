class_name ShopView
extends Control

@onready var apples_label: Label = $Header/ApplesContainer/ApplesLabel
@onready var count_label: Label = $Header/CountLabel
@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var back_button: Button = $Header/BackButton
@onready var random_button: Button = $BottomBar/RandomButton

const KNIFE_CELL_SCENE := preload("res://scenes/shop/KnifeCell.tscn")

var cell_instances: Array[KnifeCell] = []

func _ready() -> void:
	back_button.pressed.connect(on_back_pressed)
	random_button.pressed.connect(on_random_pressed)
	EventBus.apples_changed.connect(func(_a): refresh_header())
	EventBus.skin_changed.connect(func(_k): refresh_cells())
	
	populate_knives()
	refresh_header()

func populate_knives() -> void:
	for c in grid_container.get_children():
		c.queue_free()
	cell_instances.clear()
	
	var knives := ShopManager.get_all_knives()
	for k_data in knives:
		var cell: KnifeCell = KNIFE_CELL_SCENE.instantiate()
		grid_container.add_child(cell)
		cell.setup(k_data)
		cell.cell_clicked.connect(on_cell_clicked.bind(cell))
		cell_instances.append(cell)

func refresh_header() -> void:
	apples_label.text = str(Save.apples)
	var unlocked := ShopManager.get_unlocked_count()
	var total := ShopManager.get_total_count()
	count_label.text = "%d / %d" % [unlocked, total]

func refresh_cells() -> void:
	for cell in cell_instances:
		cell.update_state()
	refresh_header()

func on_cell_clicked(k_data: Dictionary, cell: KnifeCell) -> void:
	var kid: String = k_data.get("id", "")
	var price: int = k_data.get("price", 0)
	
	if Save.is_knife_unlocked(kid):
		Save.equip_knife(kid)
		refresh_cells()
	else:
		if Save.can_afford(price):
			Save.purchase_knife(kid, price)
			refresh_cells()
		else:
			cell.shake()

func on_random_pressed() -> void:
	AudioManager.play_click()
	var unlocked := ShopManager.unlock_random_knife()
	if unlocked.size() > 0:
		refresh_cells()
	else:
		# Shake random button to indicate insufficient apples
		var tw := create_tween()
		var orig_x := random_button.position.x
		tw.tween_property(random_button, "position:x", orig_x - 12.0, 0.04)
		tw.tween_property(random_button, "position:x", orig_x + 12.0, 0.04)
		tw.tween_property(random_button, "position:x", orig_x - 8.0, 0.04)
		tw.tween_property(random_button, "position:x", orig_x, 0.04)

func on_back_pressed() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")
