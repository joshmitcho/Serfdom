# item_container.gd

extends Node
class_name ItemContainer

signal items_changed(indexes: Array)

var items: Array[Item]
var bars_unlocked: int
var slots_unlocked: int

func _ready():
	set_bars_unlocked(1)
	set_initial_items()


func set_initial_items():
	items.resize(Inventory.MAX_SIZE + 1)


func set_bars_unlocked(num_bars: int):
	bars_unlocked = num_bars
	slots_unlocked = bars_unlocked * Inventory.BAR_SIZE
	print(self, " slots_unlocked: ", slots_unlocked)


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


func update_item_amount(item_index, delta):
	if items[item_index].amount + delta <= 0:
		remove_item(item_index)
	else:
		items[item_index].amount += delta
		emit_signal("items_changed", [item_index])


func remove_item(item_index) -> Item:
	var previous_item = items[item_index]
	items[item_index] = null
	emit_signal("items_changed", [item_index])
	return previous_item


func does_container_have_room(new_item: Item) -> bool:
	for i in slots_unlocked:
		if items[i] == null or (items[i].item_name == new_item.item_name and new_item.is_stackable):
			return true
	return false


func drop_item():
	var dropped_item = remove_item(Inventory.CURSOR_INDEX)
	emit_signal("item_dropped", Inventory.CURSOR_INDEX, dropped_item)
	emit_signal("items_changed", [Inventory.CURSOR_INDEX])

func is_empty() -> bool:
	for item in items:
		if is_instance_of(item, Item):
			return false
	return true
