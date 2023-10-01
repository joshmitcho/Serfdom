#item_slot.gd
extends CenterContainer

class_name ItemSlot

signal became_active_slot(index: int)

var item_sprite: ShadowSprite
var locked: bool = true
var slot_index: int = 0

var parent: ItemContainer
var is_hideable: bool = false
var is_full: bool = false

@onready var item_amount_label = %ItemAmountLabel
@onready var hotkey_label = %HotkeyLabel
@onready var highlight: Sprite2D = $Highlight
@onready var pail_fill_level: ColorRect = %PailFillLevel

func _ready():
	item_sprite = $ShadowSprite
	item_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites)
	item_sprite.visible = false
	highlight.visible = false
	pail_fill_level.visible = false

func display_item(item: Item):
	if is_instance_of(item, Item):
		item_sprite.visible = true
		item_sprite.change_frame(item.compendium_index)
	
		if item.amount > 1:
			item_amount_label.text = str(item.amount)
		else:
			item_amount_label.text = ""
		is_full = true
		
		var item_name_split = item.item_name.split("_")
		if item_name_split[-1] == StringName("pail"):
			pail_fill_level.visible = true
			pail_fill_level.size.x = (item.power * 1.0 / Compendium.TOOL_TIERS[item_name_split[0]]) * 16
		
	else:
		item_sprite.visible = false
		item_amount_label.text = ""
		is_full = false
		pail_fill_level.visible = false

func _on_clicked():
	if locked:
		return
	
	if MainUI.is_open:
		move_items_with_cursor_behaviour()
	elif Inventory.opened_chest != null:
		open_chest_behaviour(Inventory.opened_chest)
	elif not MainUI.is_open and not Inventory.does_cursor_have_item(): # change active slot behaviour
		emit_signal("became_active_slot", slot_index)
		Inventory.set_active_slot(slot_index)
	else:
		move_items_with_cursor_behaviour()

func move_items_with_cursor_behaviour():
	var my_item = Inventory.items[slot_index]
	var cursor_item = Inventory.items[Inventory.CURSOR_INDEX]
	
	if (is_instance_of(my_item, Item) and is_instance_of(cursor_item, Item)
	and my_item.item_name == cursor_item.item_name and my_item.is_stackable):
		if my_item.amount + cursor_item.amount <= Inventory.MAX_STACK_AMOUNT:
			Inventory.increment_item_amount(slot_index, cursor_item.amount)
			Inventory.increment_item_amount(Inventory.CURSOR_INDEX, -cursor_item.amount)
		else:
			var amount_addable = Inventory.MAX_STACK_AMOUNT - my_item.amount
			if amount_addable == 0:
				Inventory.swap_items(slot_index, Inventory.CURSOR_INDEX)
			else:
				Inventory.increment_item_amount(slot_index, amount_addable)
				Inventory.increment_item_amount(Inventory.CURSOR_INDEX, -amount_addable)
	else:
		Inventory.swap_items(slot_index, Inventory.CURSOR_INDEX)


func open_chest_behaviour(open_chest: ItemContainer):
	var my_item = parent.items[slot_index]
	if my_item == null:
		return
	if parent == open_chest:
		if Inventory.does_container_have_room(my_item):
			parent.remove_item(slot_index)
			Inventory.add_items_to_inventory(my_item, my_item.amount)
			Inventory.emit_signal("close_tooltip", my_item)
	else:
		if open_chest.does_container_have_room(my_item):
			parent.remove_item(slot_index)
			open_chest.add_items_to_inventory(my_item, my_item.amount)
			Inventory.emit_signal("close_tooltip", my_item)


func _on_hover_trigger_mouse_shape_entered(_shape_idx):
	if is_instance_of(parent.items[slot_index], Item):
		Inventory.emit_signal("open_tooltip", parent.items[slot_index])


func _on_hover_trigger_mouse_shape_exited(_shape_idx):
	if is_instance_of(parent.items[slot_index], Item):
		Inventory.emit_signal("close_tooltip", parent.items[slot_index])
