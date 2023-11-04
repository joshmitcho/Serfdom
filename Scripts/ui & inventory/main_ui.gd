#main_ui.gd
extends Control

class_name MainUI

@onready var inventory_texture_rect: TextureRect = $InventoryTexture
@onready var tab_bar: TabBar = %TabBar
@onready var inventory_display: InventoryDisplay = %InventoryDisplay

var is_hotbar_at_top: bool = false
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
	Inventory.chest_opened.connect(open_chest)
	Inventory.chest_closed.connect(close_chest)
	SettingsManager.zoom_changed.connect(_on_zoom_changed)
	
	inventory_atlas.atlas = inventory_texture
	
	menu_pages = get_children()
	menu_pages.pop_front()
	close_menu()
	
	cursor_item_display = preload("res://Scenes/ui & inventory/cursor_item_display.tscn").instantiate()
	add_child(cursor_item_display)


func open_menu(tab: int = 0):
	tab_bar.current_tab = tab
	tab_bar.show()
	inventory_atlas.region = inventory_atlas_rects[Inventory.bars_unlocked - 1]
	inventory_texture_rect.texture = inventory_atlas
	inventory_texture_rect.reset_size()
	inventory_texture_rect.set_anchors_preset(PRESET_CENTER, true)
	if is_hotbar_at_top:
		inventory_texture_rect.position.y -= hotbar_texture.get_height()
	
	for slot in inventory_display.slots:
		if slot.is_hideable:
			slot.show()


func open_chest():
	inventory_atlas.region = inventory_atlas_rects[Inventory.bars_unlocked - 1]
	inventory_texture_rect.texture = inventory_atlas
	inventory_texture_rect.reset_size()
	inventory_texture_rect.set_anchors_preset(PRESET_CENTER, true)
	inventory_texture_rect.position.y += hotbar_texture.get_height()
	if is_hotbar_at_top:
		inventory_texture_rect.position.y -= hotbar_texture.get_height()
	
	for slot in inventory_display.slots:
		if slot.is_hideable:
			slot.show()


func close_chest():
	inventory_texture_rect.texture = hotbar_texture
	inventory_texture_rect.reset_size()
	inventory_texture_rect.position.y -= hotbar_texture.get_height()
	if is_hotbar_at_top:
		inventory_texture_rect.set_anchors_preset(PRESET_CENTER_TOP, true)
		inventory_texture_rect.position.y = 0
	else:
		inventory_texture_rect.set_anchors_preset(PRESET_CENTER_BOTTOM, true)
	
	for slot in inventory_display.slots:
		if slot.is_hideable:
			slot.hide()


func close_menu():
	tab_bar.current_tab = 0
	tab_bar.hide()
	inventory_texture_rect.texture = hotbar_texture
	inventory_texture_rect.reset_size()
	if is_hotbar_at_top:
		inventory_texture_rect.set_anchors_preset(PRESET_CENTER_TOP, true)
		inventory_texture_rect.position.y = 0
	else:
		inventory_texture_rect.set_anchors_preset(PRESET_CENTER_BOTTOM, true)
	
	for slot in inventory_display.slots:
		if slot.is_hideable:
			slot.hide()


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
			menu_pages[i].show()
		else:
			menu_pages[i].hide()


func _on_zoom_changed():
	inventory_texture_rect.reset_size()


func _hotbar_to_top():
	if not is_hotbar_at_top:
		inventory_texture_rect.set_anchors_preset(PRESET_CENTER_TOP, true)
		inventory_texture_rect.position.y = 0
		is_hotbar_at_top = true


func _hotbar_to_bottom():
	if is_hotbar_at_top:
		inventory_texture_rect.set_anchors_preset(PRESET_CENTER_BOTTOM, true)
		inventory_texture_rect.position.y -= hotbar_texture.get_height()
		is_hotbar_at_top = false
