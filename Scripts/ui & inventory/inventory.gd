extends ItemContainer

signal money_supply_changed(new_value: int)
signal item_dropped(index: int, item: Item)
signal active_slot_changed(index: int)
signal toggle_menu(tab: int)
signal chest_opened()
signal chest_closed()
signal open_tooltip(item: Item)
signal close_tooltip(item: Item)

var active_index = 0
var opened_chest: ItemContainer
var money_supply: int = 50
var has_lantern: bool = true

const BAR_SIZE = 9
const MAX_BARS = 3
const MAX_SIZE = BAR_SIZE * MAX_BARS
const CURSOR_INDEX = MAX_SIZE

const MAX_STACK_AMOUNT = 100


func _ready():
	set_bars_unlocked(1)
	set_initial_items()


func set_initial_items():
	items.resize(MAX_SIZE + 1)
	add_items_to_inventory(Compendium.all_items["rusty_axe"])
	add_items_to_inventory(Compendium.all_items["rusty_hammer"])
	add_items_to_inventory(Compendium.all_items["rusty_sickle"])
	add_items_to_inventory(Compendium.all_items["rusty_shovel"])
	add_items_to_inventory(Compendium.all_items["rusty_pail"])
#	add_items_to_inventory(Compendium.all_items["crude_chest"])
	add_items_to_inventory(Compendium.all_items["wheat_seeds"], 15)
	add_items_to_inventory(Compendium.all_items["irrigation_pipe"], 15)


func increment_active_slot(delta: int):
	var new_active_slot = (active_index + delta) % BAR_SIZE
	if new_active_slot < 0:
		new_active_slot = BAR_SIZE
	set_active_slot(new_active_slot)


func set_active_slot(index: int):
	if index != active_index:
		active_index = index
		emit_signal("active_slot_changed", index)


func get_current_tool_type() -> StringName:
	var active_item: Item = items[active_index]
	if is_instance_of(active_item, Item) and active_item.is_tool:
		return active_item.item_name.split("_")[-1]
	return ""


func get_current_item() -> Item:
	return items[active_index]


func does_cursor_have_item():
	return is_instance_of(items[Inventory.CURSOR_INDEX], Item)


func shift_toolbar():
	for index in slots_unlocked - BAR_SIZE:
		var new_index = (index + BAR_SIZE)
		swap_items(index, new_index)


func increment_money_supply(delta_value: int):
	money_supply += delta_value
	emit_signal("money_supply_changed", money_supply)
