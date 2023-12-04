#craftable_slot.gd
extends Control

class_name CraftableSlot

signal item_crafted(item: Item)

var has_ingredients: bool = false

var result_item: Item
var result_sprite: ShadowedSprite


func load_result(item: Item):
	result_sprite = %ResultSprite
	result_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites)
	result_item = item
	result_sprite.change_frame(result_item.compendium_index)
	set_state_has_ingredients(false)


func _on_clicked():
	if Inventory.does_cursor_have_item() and Inventory.items[Inventory.CURSOR_INDEX].item_name != result_item.item_name:
		return
	
	if has_ingredients and Inventory.does_container_have_room(result_item):
		for recipe_component in result_item.get_recipe():
			var component_index = Inventory.find_item_index(recipe_component.item_name)
			Inventory.increment_item_amount(component_index, -recipe_component.amount)
		Inventory.add_item(result_item)
		item_crafted.emit(result_item)
		SoundManager.play_pitched_sfx(Compendium.sfx_pop)
	else:
		SoundManager.play_pitched_sfx(Compendium.error_sfx, 1.0, 10)


func set_state_has_ingredients(new_value: bool):
	has_ingredients = new_value
	if has_ingredients:
		modulate = Color.WHITE
	else:
		modulate = Color(1, 1, 1, 0.4)


func _on_button_mouse_entered():
	Inventory.open_tooltip.emit(result_item, true)


func _on_button_mouse_exited():
	Inventory.close_tooltip.emit(result_item)
