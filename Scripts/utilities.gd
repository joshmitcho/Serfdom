# utilities.gd
extends Node

signal zoom_changed()

const ZOOM_LEVELS = [
	Vector2i(320, 180), Vector2i(480, 270), Vector2i(640, 360)
]
var current_zoom: int = 0


func get_children_of_type(node: Node, child_type):
	var list = []
	
	for i in node.get_child_count():
		var child = node.get_child(i)
		if is_instance_of(child, child_type):
			list.append(child)
	return list

func delayed_call(callable: Callable, delay: float):
	get_tree().create_timer(delay, false).timeout.connect(callable)
	
func toggle_zoom():
	current_zoom = (current_zoom + 1) % ZOOM_LEVELS.size()
	get_tree().root.content_scale_size = ZOOM_LEVELS[current_zoom]
	emit_signal("zoom_changed")
	
func toggle_fullscreen():
	if get_tree().root.mode == Window.MODE_FULLSCREEN:
		get_tree().root.mode = Window.MODE_MAXIMIZED
	else:
		get_tree().root.mode = Window.MODE_FULLSCREEN

