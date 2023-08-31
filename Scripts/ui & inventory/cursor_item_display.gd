extends CenterContainer
class_name CursorItemDisplay

var item_sprite: ShadowSprite
@onready var item_amount_label = %ItemAmountLabel

func _ready():
	item_sprite = $ShadowSprite
	item_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites, Vector2i(-3, 5))
	item_sprite.visible = false

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
	var my_item_index = get_index()
	var my_item = Inventory.items[my_item_index]
	var cursor_item = Inventory.items[Inventory.CURSOR_INDEX]
	
	if (is_instance_of(my_item, Item) and is_instance_of(cursor_item, Item)
	and my_item.item_name == cursor_item.item_name and my_item.stackable):
		Inventory.update_item_amount(my_item_index, cursor_item.amount)
		Inventory.remove_item(Inventory.CURSOR_INDEX)
	else:
		Inventory.swap_items(get_index(), Inventory.CURSOR_INDEX)

func _process(_delta):
	global_position = get_viewport().get_mouse_position()
