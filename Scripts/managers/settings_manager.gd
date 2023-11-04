# settings_manager.gd
extends Node

signal zoom_changed()

const ZOOM_LEVELS = [
	Vector2i(320, 180), Vector2i(480, 270), Vector2i(640, 360)
]
var current_zoom: int = 0


func toggle_zoom():
	current_zoom = (current_zoom + 1) % ZOOM_LEVELS.size()
	get_tree().root.content_scale_size = ZOOM_LEVELS[current_zoom]
	zoom_changed.emit()


func toggle_fullscreen():
	if get_tree().root.mode == Window.MODE_FULLSCREEN:
		get_tree().root.mode = Window.MODE_WINDOWED
	else:
		get_tree().root.mode = Window.MODE_FULLSCREEN