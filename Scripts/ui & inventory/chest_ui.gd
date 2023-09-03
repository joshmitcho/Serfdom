#chest_ui.gd
extends TextureRect

class_name ChestUI

@export var item_container: ItemContainer
@export var atlas: AtlasTexture

@onready var item_container_display: ItemContainerDisplay = %ItemContainerDisplay

var inventory_atlas_rects = [
	Rect2(0, 0, 254, 79), Rect2(0, 79, 254, 85), Rect2(0, 158, 254, 85)
]

static var is_open: bool = false


func _ready():
	Utils.zoom_changed.connect(_on_zoom_changed)
	atlas.region = inventory_atlas_rects[0]
	texture = atlas
	close_chest_ui()


func open_chest_ui():
	reset_size()
	visible = true
	is_open = true


func close_chest_ui():
	visible = false
	is_open = false


func _on_zoom_changed():
	reset_size()
