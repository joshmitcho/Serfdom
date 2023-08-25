#inventory_display.gd
extends BoxContainer

class_name InventoryDisplay

var hotbar_hotkeys = [";", "<", "=", ">", "?", "@", "A", "B", "C"]

@onready var sfx_player: AudioStreamPlayer = %AudioStreamPlayer
var swap_tool_sfx = preload("res://SFX/toolSwap.wav")

var slots: Array

func _ready():
	Inventory.items_changed.connect(on_items_changed)
	Inventory.active_slot_changed.connect(set_active_slot_display)
	Inventory.make_items_unique()
	load_slots()
	initialize_inventory_display()
	
func load_slots():
	var i = 0
	for slot in %HotbarSlots.get_children():
		slot.slot_index = i
		slots.push_back(slot)
		i += 1
	for slot in %OtherSlots.get_children():
		slot.slot_index = i
		slots.push_back(slot)
		i += 1

func initialize_inventory_display():
	for i in Inventory.slots_unlocked:
		update_inventory_slot_display(i)
		slots[i].locked = false
	for i in Inventory.MAX_SIZE:
		slots[i].hotkey_label.text = ""
	for i in Inventory.BAR_SIZE:
		slots[i].hotkey_label.text = hotbar_hotkeys[i]
	slots[Inventory.active_index].highlight.visible = true
	
func on_items_changed(indexes: Array):
	for item_index in indexes:
		update_inventory_slot_display(item_index)

func update_inventory_slot_display(item_index: int):
	var slot_display
	if item_index == Inventory.CURSOR_INDEX:
		slot_display = $"../CursorItemDisplay"
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

