extends Control
class_name RecipeIngredient

var sprite: ShadowedSprite
var amount_label: Label
var ingredient_name: Label


func load_ingredient_data(item: Item):
	sprite = $Control/ShadowedSprite
	amount_label = $ItemAmountLabel
	ingredient_name = %IngredientName
	sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites)
	sprite.change_frame(item.compendium_index)
	amount_label.text = str(item.amount)
	ingredient_name.text = item.item_name.capitalize()
	if Inventory.has_item(item.item_name, item.amount):
		ingredient_name.add_theme_color_override("font_color", Color.WHITE)
		ingredient_name.add_theme_color_override("font_shadow_color", Color("cf8068"))
	else:
		ingredient_name.add_theme_color_override("font_color", Color.RED)
		ingredient_name.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
