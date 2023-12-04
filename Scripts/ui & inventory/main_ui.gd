#main_ui.gd
extends Control

class_name MainUI

@onready var inventory_texture_rect: TextureRect = $InventoryTexture
@onready var tab_bar: TabBar = $TabBar
@onready var inventory_display: InventoryDisplay = %InventoryDisplay
@onready var craftables_display: CraftablesDisplay = %CraftablesDisplay


var is_hotbar_at_top: bool = false
const HOTBAR_TEXTURE = preload("res://Art/UI/hotbar.png")
const INVENTORY_TEXTURE = preload("res://Art/UI/inventory.png")
var inventory_atlas: AtlasTexture = AtlasTexture.new()
var inventory_atlas_rects = [
	Rect2(0, 0, 222, 85), Rect2(0, 85, 222, 85), Rect2(0, 170, 222, 85)
]

static var is_open: bool = false
static var cursor_item_display: CursorItemDisplay
var menu_pages: Array

func _ready():
	Inventory.toggle_menu.connect(toggle_menu)
	Inventory.chest_opened.connect(show_inventory_display)
	Inventory.chest_closed.connect(hide_inventory_display)
	SettingsManager.zoom_changed.connect(_on_zoom_changed)
	
	inventory_atlas.atlas = INVENTORY_TEXTURE
	
	menu_pages = get_children()
	menu_pages.pop_front()
	menu_pages.pop_back()
	_on_tab_changed(-1)
	tab_bar.hide()
	
	cursor_item_display = preload("res://Scenes/ui & inventory/cursor_item_display.tscn").instantiate()
	add_child(cursor_item_display)


func open_menu(tab: int = 0):
	craftables_display.calculate_all_known_recipes()
	tab_bar.current_tab = tab
	tab_bar.show()
	_on_tab_changed(tab)
	show_inventory_display()


func close_menu():
	tab_bar.current_tab = 0
	tab_bar.hide()
	_on_tab_changed(-1)
	hide_inventory_display()


func show_inventory_display():
	inventory_atlas.region = inventory_atlas_rects[Inventory.bars_unlocked - 1]
	inventory_texture_rect.texture = inventory_atlas
	inventory_texture_rect.reset_size()
	inventory_texture_rect.set_anchors_preset(PRESET_CENTER, true)
	if not is_hotbar_at_top:
		inventory_texture_rect.position.y += HOTBAR_TEXTURE.get_height()
	inventory_texture_rect.position.y += 6
	
	for slot in inventory_display.slots:
		if slot.is_hideable:
			slot.show()


func hide_inventory_display():
	inventory_texture_rect.texture = HOTBAR_TEXTURE
	inventory_texture_rect.reset_size()

	if is_hotbar_at_top:
		inventory_texture_rect.set_anchors_preset(PRESET_CENTER_TOP, true)
		inventory_texture_rect.position.y = 0
	else:
		inventory_texture_rect.set_anchors_preset(PRESET_CENTER_BOTTOM, true)
		inventory_texture_rect.position.y -= HOTBAR_TEXTURE.get_height() + 6
	
	for slot in inventory_display.slots:
		if slot.is_hideable:
			slot.hide()


func toggle_menu(tab: int):
	if is_open:
		if tab_bar.current_tab == tab:
			close_menu()
			is_open = false
		else:
			tab_bar.current_tab = tab
			_on_tab_changed(tab)
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
		inventory_texture_rect.position.y -= HOTBAR_TEXTURE.get_height()
		is_hotbar_at_top = false
