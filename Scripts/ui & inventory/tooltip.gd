# tooltip.gd

extends Control
class_name Tooltip

@onready var item_name: Label = %ItemName
@onready var item_tag: Label = %ItemTag
@onready var item_description: Label = %ItemDescription

@onready var top = $Top
@onready var stretch_top = $StretchTop
@onready var middle = $Middle
@onready var stretch_bottom = $StretchBottom

var near_top_of_screen: bool = false
var current_item: Item
var description_lines: int
var name_lines: int


func _ready():
	Inventory.open_tooltip.connect(open)
	Inventory.close_tooltip.connect(close)
	visible = false

func open(item: Item):
	current_item = item
	item_name.text = item.item_name.capitalize()
	item_tag.text = item.tag.to_upper()
	item_description.text = item.description
	
	visible = true
	adjust_sizes.call_deferred()


func adjust_sizes():
	description_lines = item_description.get_line_count()
	name_lines = item_name.get_line_count()
	
	middle.position.y = (description_lines + 1) * -8 - (description_lines + 3)
	stretch_bottom.position.y = middle.position.y + 8
	top.position.y = middle.position.y - (name_lines + 1) * 11 - (name_lines + 1)
	stretch_top.position.y = top.position.y + 8
	
	stretch_bottom.scale.y = description_lines
	stretch_top.scale.y = 2 + (name_lines * 2)


func close(item_from_exited_slot: Item):
	if item_from_exited_slot.item_name == current_item.item_name:
		visible = false


func _process(_delta):
	var mouse_position = get_viewport().get_mouse_position()
	var top_position = top.position.y * -1
	
	if mouse_position.y < top_position:
		near_top_of_screen = true
	else:
		near_top_of_screen = false
	
	if near_top_of_screen:
		global_position = mouse_position + Vector2(0, top_position)
	else:
		global_position = mouse_position
