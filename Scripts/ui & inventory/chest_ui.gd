#chest_ui.gd
extends TextureRect

class_name ChestUI

@export var item_container: ItemContainer
@export var chest_atlas: AtlasTexture

@onready var item_container_display: ItemContainerDisplay = $ItemContainerDisplay


var chest_atlas_rects = [
	Rect2(0, 0, 254, 79), Rect2(0, 79, 254, 79), Rect2(0, 158, 254, 79)
]
var item_container_display_offsets = [28, 15, 4]

static var is_open: bool = false


func _ready():
	SettingsManager.zoom_changed.connect(_on_zoom_changed)
	texture = chest_atlas
	hide()


func open_chest_ui():
	set_modulate(UIModulate.current_color)
	SoundManager.play_pitched_sfx(Compendium.chest_open_sfx)
	chest_atlas.region = chest_atlas_rects[item_container.bars_unlocked - 1]
	reset_size()
	item_container_display.position.y = item_container_display_offsets[item_container.bars_unlocked - 1]
	show()
	is_open = true


func close_chest_ui():
	SoundManager.play_pitched_sfx(Compendium.chest_close_sfx)
	hide()
	is_open = false


func _on_zoom_changed():
	reset_size()
