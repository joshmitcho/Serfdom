#item_container_display.gd
extends BoxContainer
class_name ItemContainerDisplay

@onready var sfx_player: AudioStreamPlayer = %AudioStreamPlayer
var swap_tool_sfx = preload("res://SFX/toolSwap.wav")

var slots: Array[ItemSlot]
var slots_containers: Array
@export var parent: ItemContainer

func _ready():
	load_slots(%Slots.get_children())
	initialize_inventory_display()


func load_slots(container: Array):
	var i = 0
	for slot in container:
		slot.slot_index = i
		slot.became_active_slot.connect(set_active_slot_display)
		slots.push_back(slot)
		i += 1
#	print("slots in load_slots = ", slots.size())


func initialize_inventory_display():
	for slot in slots:
		slot.parent = parent
		slot.hotkey_label.text = ""
	print("parent slots_unlocked: ", parent.slots_unlocked)
	for i in parent.slots_unlocked:
		update_inventory_slot_display(i)
		slots[i].locked = false


func on_items_changed(indexes: Array):
#	print("slots in on_items_changed: ", slots.size())
	for item_index in indexes:
		update_inventory_slot_display(item_index)


func update_inventory_slot_display(item_index: int):
	var item = parent.items[item_index]
	slots[item_index].display_item(item)


func set_active_slot_display(index: int):
	for slot in slots:
		slot.highlight.visible = false
	slots[index].highlight.visible = true
	sfx_player.set_stream(swap_tool_sfx)
	sfx_player.play()
