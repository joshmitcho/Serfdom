#inventory_display.gd
extends ItemContainerDisplay
class_name InventoryDisplay

var hotbar_hotkeys = [";", "<", "=", ">", "?", "@", "A", "B", "C"]


func _ready():
	Inventory.items_changed.connect(on_items_changed)
	Inventory.active_slot_changed.connect(set_active_slot_display)
	load_slots(%HotbarSlots.get_children() + %OtherSlots.get_children())
	initialize_item_container_display()


func initialize_item_container_display():
	for slot in slots:
		slot.parent = Inventory
	for i in Inventory.MAX_SIZE:
		slots[i].hotkey_label.text = ""
		slots[i].item_amount_label.text = ""
		slots[i].shadow_spill_cover.hide()
	for i in Inventory.slots_unlocked:
		update_inventory_slot_display(i)
		slots[i].locked = false
		slots[i].shadow_spill_cover.show()
	for i in Inventory.BAR_SIZE:
		slots[i].hotkey_label.text = hotbar_hotkeys[i]
	slots[Inventory.active_index].highlight.show()


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
		slot.highlight.hide()
	slots[index].highlight.show()
	SoundManager.play_pitched_sfx(swap_tool_sfx)
