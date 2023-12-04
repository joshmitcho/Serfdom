# settings_manager.gd
extends Node

signal zoom_changed()

const CURSORS = [
	preload("res://Art/cursor_96.png"),
	preload("res://Art/cursor_64.png"),
	preload("res://Art/cursor_48.png")
]
const CURSOR_HOTSPOTS = [Vector2(6, 6), Vector2(4, 4), Vector2(3, 3)]
const ZOOM_LEVELS = [
	Vector2i(320, 180), Vector2i(480, 270), Vector2i(640, 360)
]
var current_zoom: int = 0


func toggle_zoom():
	current_zoom = (current_zoom + 1) % ZOOM_LEVELS.size()
	get_tree().root.content_scale_size = ZOOM_LEVELS[current_zoom]
	Input.set_custom_mouse_cursor(CURSORS[current_zoom], Input.CURSOR_ARROW, CURSOR_HOTSPOTS[current_zoom])
	zoom_changed.emit()


func toggle_fullscreen():
	if get_tree().root.mode == Window.MODE_FULLSCREEN:
		get_tree().root.mode = Window.MODE_WINDOWED
	else:
		get_tree().root.mode = Window.MODE_FULLSCREEN
