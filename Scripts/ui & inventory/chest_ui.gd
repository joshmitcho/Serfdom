#chest_ui.gd
extends TextureRect

class_name ChestUI

@export var item_container: ItemContainer
@export var chest_atlas: AtlasTexture

@onready var item_container_display: ItemContainerDisplay = %ItemContainerDisplay
@onready var sfx_player: AudioStreamPlayer = %AudioStreamPlayer

var open_sfx = preload("res://SFX/chest_open.wav")
var close_sfx = preload("res://SFX/chest_close.wav")

var chest_atlas_rects = [
	Rect2(0, 0, 254, 79), Rect2(0, 79, 254, 79), Rect2(0, 158, 254, 79)
]
var item_container_display_offsets = [32, 19, 8]

static var is_open: bool = false


func _ready():
	Utils.zoom_changed.connect(_on_zoom_changed)
	texture = chest_atlas
	visible = false


func open_chest_ui():
	set_modulate(UIModulate.current_color)
	sfx_player.set_stream(open_sfx)
	sfx_player.play()
	chest_atlas.region = chest_atlas_rects[item_container.bars_unlocked - 1]
	reset_size()
	item_container_display.position.y = item_container_display_offsets[item_container.bars_unlocked - 1]
	visible = true
	is_open = true


func close_chest_ui():
	sfx_player.set_stream(close_sfx)
	sfx_player.play()
	visible = false
	is_open = false


func _on_zoom_changed():
	reset_size()