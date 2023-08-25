#inventory_slot_display.gd
extends CenterContainer

class_name InventorySlotDisplay

var item_sprite: ShadowSprite
var locked: bool = true
var slot_index: int = 0

@onready var item_amount_label = %ItemAmountLabel
@onready var hotkey_label = %HotkeyLabel
@onready var highlight: Sprite2D = $Highlight

func _ready():
	item_sprite = $ShadowSprite
	item_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites)
	item_sprite.visible = false
	highlight.visible = false

func display_item(item: Item):
	if is_instance_of(item, Item):
		item_sprite.visible = true
		item_sprite.change_frame(item.compendium_index)
	
		if item.amount > 1:
			item_amount_label.text = str(item.amount)
		else:
			item_amount_label.text = ""
			
	else:
		item_sprite.visible = false
		item_amount_label.text = ""

func _on_clicked():
	if locked:
		return
	var my_item = Inventory.items[slot_index]
	var cursor_item = Inventory.items[Inventory.CURSOR_INDEX]
	
	if (is_instance_of(my_item, Item) and is_instance_of(cursor_item, Item)
	and my_item.item_name == cursor_item.item_name and my_item.is_stackable):
		Inventory.update_item_amount(slot_index, cursor_item.amount)
		Inventory.remove_item(Inventory.CURSOR_INDEX)
	else:
		Inventory.swap_items(slot_index, Inventory.CURSOR_INDEX)
	
	
