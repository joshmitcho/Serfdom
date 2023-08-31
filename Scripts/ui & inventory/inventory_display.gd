#inventory_display.gd
extends ItemContainerDisplay

class_name InventoryDisplay

var hotbar_hotkeys = [";", "<", "=", ">", "?", "@", "A", "B", "C"]


func _ready():
	Inventory.items_changed.connect(on_items_changed)
	Inventory.active_slot_changed.connect(set_active_slot_display)
	load_slots(%HotbarSlots.get_children() + %OtherSlots.get_children())
	initialize_inventory_display()


func initialize_inventory_display():
	for slot in slots:
		slot.parent = Inventory
	for i in Inventory.slots_unlocked:
		update_inventory_slot_display(i)
		slots[i].locked = false
	for i in Inventory.MAX_SIZE:
		slots[i].hotkey_label.text = ""
	for i in Inventory.BAR_SIZE:
		slots[i].hotkey_label.text = hotbar_hotkeys[i]
	slots[Inventory.active_index].highlight.visible = true


func update_inventory_slot_display(item_index: int):
	var slot_display
	if item_index == Inventory.CURSOR_INDEX:
		slot_display = MainUI.cursor_item_display
	else:
		slot_display = slots[item_index]
	
	var item = Inventory.items[item_index]
	slot_display.display_item(item)


func set_active_slot_display(index: int):
	for slot in slots:
		slot.highlight.visible = false
	slots[index].highlight.visible = true
	sfx_player.set_stream(swap_tool_sfx)
	sfx_player.play()
