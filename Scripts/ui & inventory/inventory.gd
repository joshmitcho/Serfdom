#inventory.gd
extends ItemContainer

signal money_supply_changed(new_value: int)
signal active_slot_changed(index: int)
signal toggle_menu(tab: int)
signal chest_opened()
signal chest_closed()
signal open_tooltip(item: Item, show_recipe: bool)
signal close_tooltip(item: Item)
signal new_recipe_learned(recipe_name: String)
signal item_crafted(item: Item)

var known_recipe_names: Array[String]

var active_index = 0
var opened_chest: ItemContainer
var money_supply: int = 50
var has_lantern: bool = true

const BAR_SIZE = 9
const MAX_BARS = 3
const MAX_SIZE = BAR_SIZE * MAX_BARS
const CURSOR_INDEX = MAX_SIZE

const MAX_STACK_AMOUNT = 999


func _ready() -> void:
	set_bars_unlocked(1)
	set_initial_items()
	set_initial_recipes()


func set_initial_items() -> void:
	items.resize(MAX_SIZE + 1)
	add_item(Compendium.all_items["rusty_axe"])
	add_item(Compendium.all_items["rusty_hammer"])
	add_item(Compendium.all_items["rusty_sickle"])
	add_item(Compendium.all_items["rusty_shovel"])
	add_item(Compendium.all_items["rusty_pail"])
	add_item(Compendium.all_items["wheat_seeds"], 15)


func set_initial_recipes():
	learn_new_recipe("crude_chest")
	learn_new_recipe("improved_chest")
	learn_new_recipe("pickle_barrel")
	learn_new_recipe("irrigation_pipe")


func learn_new_recipe(recipe_name: String):
	known_recipe_names.append(recipe_name)
	new_recipe_learned.emit(recipe_name)


func increment_active_slot(delta: int) -> void:
	var new_active_slot = (active_index + delta) % BAR_SIZE
	if new_active_slot < 0:
		new_active_slot = BAR_SIZE
	set_active_slot(new_active_slot)


func set_active_slot(index: int) -> void:
	if index != active_index:
		active_index = index
		active_slot_changed.emit(index)


func get_current_tool_type() -> StringName:
	var active_item: Item = items[active_index]
	if active_item is Item and active_item.is_tool:
		return active_item.item_name.split("_")[-1]
	return ""


func get_current_item() -> Item:
	return items[active_index]


func does_cursor_have_item() -> bool:
	return items[Inventory.CURSOR_INDEX] is Item


func shift_toolbar() -> void:
	for index in slots_unlocked - BAR_SIZE:
		var new_index = (index + BAR_SIZE)
		swap_items(index, new_index)


func increment_money_supply(delta_value: int) -> void:
	money_supply += delta_value
	money_supply_changed.emit(money_supply)
