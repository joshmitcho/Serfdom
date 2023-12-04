#item_container_display.gd
extends Control
class_name ItemContainerDisplay

var slots: Array[ItemSlot]
var slots_containers: Array
@export var parent: ItemContainer


func _on_chest_placed():
	load_slots(%Slots.get_children())
	initialize_item_container_display()


func load_slots(container: Array):
	var i = 0
	for slot in container:
		slot.slot_index = i
		if i != Inventory.CURSOR_INDEX and i >= Inventory.BAR_SIZE:
			slot.is_hideable = true
		slot.became_active_slot.connect(set_active_slot_display)
		slots.push_back(slot)
		i += 1


func initialize_item_container_display():
	for i in Inventory.MAX_BARS * Inventory.BAR_SIZE:
		slots[i].parent = parent
		slots[i].hotkey_label.text = ""
		slots[i].item_amount_label.text = ""
	for i in parent.slots_unlocked:
		update_inventory_slot_display(i)
		slots[i].locked = false


func on_items_changed(indexes: Array):
	for item_index in indexes:
		update_inventory_slot_display(item_index)


func update_inventory_slot_display(item_index: int):
	var item = parent.items[item_index]
	slots[item_index].display_item(item)


func set_active_slot_display(index: int):
	for slot in slots:
		slot.highlight.hide()
	slots[index].highlight.show()
	SoundManager.play_pitched_sfx(Compendium.swap_tool_sfx)

