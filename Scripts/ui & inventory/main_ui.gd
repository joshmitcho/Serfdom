#main_ui.gd
extends Control

class_name MainUI

@onready var inventory_texture_rect: TextureRect = $InventoryTexture
@onready var tab_bar: TabBar = %TabBar
@onready var inventory_display: InventoryDisplay = %InventoryDisplay

var hotbar_texture = preload("res://Art/UI/hotbar.png")
var inventory_texture = preload("res://Art/UI/inventory.png")
var inventory_atlas: AtlasTexture = AtlasTexture.new()
var inventory_atlas_rects = [
	Rect2(0, 0, 222, 85), Rect2(0, 85, 222, 85), Rect2(0, 170, 222, 85)
]

static var is_open: bool = false
static var cursor_item_display: CursorItemDisplay
var menu_pages: Array

func _ready():
	Inventory.toggle_menu.connect(toggle_menu)
	Utils.zoom_changed.connect(_on_zoom_changed)
	
	inventory_atlas.atlas = inventory_texture
	
	menu_pages = get_children()
	menu_pages.pop_front()
	close_menu()
	
	cursor_item_display = preload("res://Scenes/ui & inventory/cursor_item_display.tscn").instantiate()
	add_child(cursor_item_display)


func open_menu(tab: int = 0):
	tab_bar.current_tab = tab
	tab_bar.visible = true
	inventory_atlas.region = inventory_atlas_rects[Inventory.bars_unlocked - 1]
	inventory_texture_rect.texture = inventory_atlas
	inventory_texture_rect.reset_size()
	inventory_texture_rect.set_anchors_preset(PRESET_CENTER, true)


func close_menu():
	tab_bar.current_tab = 0
	tab_bar.visible = false
	inventory_texture_rect.texture = hotbar_texture
	inventory_texture_rect.reset_size()
	inventory_texture_rect.set_anchors_preset(PRESET_CENTER_BOTTOM, true)


func toggle_menu(tab: int):
	if is_open and tab_bar.current_tab == tab:
		close_menu()
		is_open = false
	else:
		open_menu(tab)
		is_open = true

func _on_tab_changed(tab):
	if Inventory.does_cursor_have_item():
		return
	
	for i in menu_pages.size():
		if i == tab:
			menu_pages[i].visible = true
		else:
			menu_pages[i].visible = false


func _on_zoom_changed():
	inventory_texture_rect.reset_size()


func _hotbar_to_top():
	inventory_texture_rect.set_anchors_preset(PRESET_CENTER_TOP, true)


func _hotbar_to_bottom():
	inventory_texture_rect.set_anchors_preset(PRESET_CENTER_BOTTOM, true)
