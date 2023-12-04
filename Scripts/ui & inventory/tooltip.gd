# tooltip.gd

extends Control
class_name Tooltip

const ingredient_base = preload("res://Scenes/ui & inventory/recipe_ingredient.tscn")

@onready var item_name: Label = %ItemName
@onready var item_tag: Label = %ItemTag
@onready var item_description: Label = %ItemDescription

@onready var top = $Top
@onready var stretch_top = $StretchTop
@onready var middle = $Middle
@onready var stretch_bottom = $StretchBottom

@onready var bottom_container = %BottomContainer
@onready var ingredients_title = %IngredientsTitle
@onready var recipe_container = %RecipeContainer

var current_item: Item


func _ready():
	Inventory.open_tooltip.connect(open)
	Inventory.close_tooltip.connect(close)
	Inventory.item_crafted.connect(refresh_tooltip_recipe)
	set_initial_sizing.call_deferred()


func open(item: Item, show_recipe: bool):
	if item is Item:
		current_item = item
		item_name.text = item.item_name.capitalize()
		item_tag.text = item.tag.to_upper()
		item_description.text = item.description
		if show_recipe:
			load_recipe(item)
			ingredients_title.show()
			recipe_container.show()
		else:
			ingredients_title.hide()
			recipe_container.hide()
		show()
		adjust_sizes.call_deferred()


func load_recipe(item: Item):
	var recipe = item.get_recipe()
	for ingredient: Item in recipe:
		var new_ingredient: RecipeIngredient = ingredient_base.instantiate()
		new_ingredient.load_ingredient_data(ingredient)
		recipe_container.add_child(new_ingredient)


func adjust_sizes():
	var name_lines = item_name.get_line_count()
	
	middle.position.y = -bottom_container.size.y - 11
	stretch_bottom.position.y = middle.position.y + 8
	top.position.y = middle.position.y - (name_lines + 1) * 11 - (name_lines + 1)
	stretch_top.position.y = top.position.y + 8
	
	stretch_bottom.scale.y = -middle.position.y / 8 - 2
	stretch_top.scale.y = 2 + (name_lines * 2)


func close(item_from_exited_slot: Item):
	if item_from_exited_slot is Item and item_from_exited_slot.item_name == current_item.item_name:
		for ingredient in recipe_container.get_children():
			recipe_container.remove_child(ingredient)
			ingredient.queue_free()
		hide()


func refresh_tooltip_recipe(item: Item):
	close(item)
	open(item, true)


func set_initial_sizing():
	ingredients_title.hide()
	recipe_container.hide()
	adjust_sizes()
	hide()


func _process(_delta):
	var mouse_position = get_viewport().get_mouse_position()
	var top_position = top.position.y * -1
	
	if mouse_position.y < top_position:
		global_position = mouse_position + Vector2(0, top_position)
	else:
		global_position = mouse_position
