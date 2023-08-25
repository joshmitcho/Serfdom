extends Node

signal money_supply_changed(new_value: int)
signal items_changed(indexes: Array)
signal item_dropped(index: int, item: Item)
signal active_slot_changed(index: int)
signal toggle_menu(tab: int)

var money_supply: int = 0

var items: Array[Item]
const BAR_SIZE = 9
const MAX_BARS = 3
const MAX_SIZE = BAR_SIZE * MAX_BARS
const CURSOR_INDEX = MAX_SIZE

var bars_unlocked = 1
var slots_unlocked = bars_unlocked * BAR_SIZE
var active_index = 0

func _ready():
	set_initial_inventory()


func set_initial_inventory():
	items.resize(MAX_SIZE + 1)
	add_items_to_inventory(Compendium.all_items["rusty_axe"])
	add_items_to_inventory(Compendium.all_items["rusty_shovel"])
	add_items_to_inventory(Compendium.all_items["rusty_sickle"])
	add_items_to_inventory(Compendium.all_items["rusty_hammer"])
	add_items_to_inventory(Compendium.all_items["rusty_pail"])
	add_items_to_inventory(Compendium.all_items["wheat_seed"], 15)
	add_items_to_inventory(Compendium.all_items["chest"], 5)


func set_active_slot(index: int):
	if index != active_index:
		active_index = index
		emit_signal("active_slot_changed", index)


func add_items_to_inventory(p_item: Item, num: int = 1):
	var item: Item = p_item.duplicate()
	item.amount = num
	
	# first check to see if new item can be stacked into existing slot
	for i in slots_unlocked:
		if is_instance_of(items[i], Item) and items[i].item_name == item.item_name and item.is_stackable:
			update_item_amount(i, item.amount)
			return
	
	# then check to see if there are empty slots
	for i in slots_unlocked:
		if items[i] == null:
			set_item(i, item)
			return


func drop_item():
	var dropped_item = remove_item(Inventory.CURSOR_INDEX)
	emit_signal("item_dropped", Inventory.CURSOR_INDEX, dropped_item)
	emit_signal("items_changed", [Inventory.CURSOR_INDEX])


func get_current_tool_type() -> StringName:
	var active_item: Item = items[active_index]
	if is_instance_of(active_item, Item) and active_item.power > 0:
		return active_item.item_name.split("_")[-1]
	return ""


func get_current_item() -> Item:
	return items[active_index]


func does_cursor_have_item():
	return is_instance_of(items[Inventory.CURSOR_INDEX], Item)


func does_inventory_have_room(new_item: Item) -> bool:
	for i in slots_unlocked:
		if items[i] == null or (items[i].item_name == new_item.item_name and new_item.is_stackable):
			return true
	return false


func update_item_amount(item_index, delta):
	if items[item_index].amount + delta <= 0:
		remove_item(item_index)
	else:
		items[item_index].amount += delta
		emit_signal("items_changed", [item_index])


func set_item(item_index, item) -> Item:
	var previous_item = items[item_index]
	items[item_index] = item
	
	emit_signal("items_changed", [item_index])
	return previous_item


func swap_items(item_index, target_item_index):
	var target_item = items[target_item_index]
	var item = items[item_index]
	
	items[target_item_index] = item
	items[item_index] = target_item
	
	emit_signal("items_changed", [item_index, target_item_index])


func remove_item(item_index) -> Item:
	var previous_item = items[item_index]
	items[item_index] = null
	emit_signal("items_changed", [item_index])
	return previous_item


func update_money_supply(delta_value: int):
	money_supply += delta_value
	emit_signal("money_supply_changed", money_supply)


func make_items_unique():
	var unique_items: Array[Item] = []
	for item in items:
		if is_instance_of(item, Item):
			unique_items.append(item.duplicate())
		else:
			unique_items.append(null)
	items = unique_items
