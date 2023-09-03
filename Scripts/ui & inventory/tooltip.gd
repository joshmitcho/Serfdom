# tooltip.gd

extends Control
class_name Tooltip

@onready var tooltip_texture_rect: TextureRect = $TextureRect
@onready var item_name: Label = %ItemName
@onready var item_tag: Label = %ItemTag
@onready var item_description: Label = %ItemDescription
var top_position: bool = false
var current_item: Item

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


func close(item_from_exited_slot: Item):
	if item_from_exited_slot.item_name == current_item.item_name:
		visible = false


func _process(_delta):
	var mouse_position = get_viewport().get_mouse_position()
	
	if mouse_position.y < tooltip_texture_rect.size.y:
		top_position = true
	else:
		top_position = false
	
	if top_position:
		global_position = mouse_position + Vector2(0, tooltip_texture_rect.size.y)
	else:
		global_position = mouse_position
