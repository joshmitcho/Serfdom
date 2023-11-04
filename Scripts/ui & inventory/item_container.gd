# item_container.gd

extends Node
class_name ItemContainer

signal items_changed(indexes: Array)
signal item_dropped(index: int, item: Item)

var items: Array[Item]
var bars_unlocked: int
var slots_unlocked: int

func _ready():
	set_bars_unlocked(Inventory.MAX_BARS)
	set_initial_items()


func set_initial_items():
	items.resize(Inventory.MAX_SIZE + 1)


func set_bars_unlocked(num_bars: int):
	bars_unlocked = num_bars
	slots_unlocked = bars_unlocked * Inventory.BAR_SIZE


func add_items_to_inventory(p_item: Item, num: int = 1):
	var item: Item = p_item.duplicate()
	item.amount = num
	
	# first check to see if new item can be stacked into existing slot
	for i in slots_unlocked:
		if items[i] is Item and items[i].item_name == item.item_name and item.is_stackable:
			if items[i].amount + item.amount <= Inventory.MAX_STACK_AMOUNT:
				increment_item_amount(i, item.amount)
				return
			elif items[i].amount < Inventory.MAX_STACK_AMOUNT:
				var leftover_amount = item.amount - (Inventory.MAX_STACK_AMOUNT - items[i].amount)
				increment_item_amount(i, item.amount - leftover_amount)
				add_items_to_inventory(item, leftover_amount)
				return
#			else:
#				continue
	
	# then check to see if there are empty slots
	for i in slots_unlocked:
		if items[i] == null:
			if item.amount <= Inventory.MAX_STACK_AMOUNT:
				set_item(i, item)
				return
			else:
				var leftover_amount = item.amount - Inventory.MAX_STACK_AMOUNT
				item.amount = Inventory.MAX_STACK_AMOUNT
				set_item(i, item)
				add_items_to_inventory(item, leftover_amount)
				return
	
	# if it ever gets here, then the container overflowed. Drop excess on the ground
	item_dropped.emit(Inventory.CURSOR_INDEX, item)


func set_item(item_index, item) -> Item:
	var previous_item = items[item_index]
	items[item_index] = item
	
	items_changed.emit([item_index])
	return previous_item


func swap_items(item_index, target_item_index):
	var target_item = items[target_item_index]
	var item = items[item_index]
	
	items[target_item_index] = item
	items[item_index] = target_item
	
	items_changed.emit([item_index, target_item_index])


func increment_item_amount(item_index, delta):
	if items[item_index].amount + delta <= 0:
		remove_item(item_index)
	else:
		items[item_index].amount += delta
		items_changed.emit([item_index])


func remove_item(item_index) -> Item:
	var previous_item = items[item_index]
	items[item_index] = null
	items_changed.emit([item_index])
	return previous_item


func does_container_have_room(new_item: Item) -> bool:
	for i in slots_unlocked:
		if items[i] == null or (
			items[i].item_name == new_item.item_name
			and new_item.is_stackable
			and items[i].amount < Inventory.MAX_STACK_AMOUNT
		):
			return true
	return false


func drop_item():
	var dropped_item = remove_item(Inventory.CURSOR_INDEX)
	item_dropped.emit(Inventory.CURSOR_INDEX, dropped_item)
	items_changed.emit([Inventory.CURSOR_INDEX])


func is_empty() -> bool:
	for item in items:
		if item is Item:
			return false
	return true


func has_item(item_name: StringName, amount: int = 1) -> bool:
	for i in items:
		if i != null and i.item_name == item_name and i.amount >= amount:
			return true
	return false
