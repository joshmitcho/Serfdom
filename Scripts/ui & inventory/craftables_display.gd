#craftables_display.gd
extends Node

class_name CraftablesDisplay

const craftable_slot_base = preload("res://Scenes/ui & inventory/craftable_slot.tscn")
var slots: Array[CraftableSlot]


func _ready():
	Inventory.new_recipe_learned.connect(add_craftable_slot)
	for recipe_name in Inventory.known_recipe_names:
		add_craftable_slot(recipe_name)


func add_craftable_slot(new_recipe_name: String):
	var new_slot: CraftableSlot = craftable_slot_base.instantiate()
	new_slot.load_result(Compendium.all_items[new_recipe_name])
	new_slot.item_crafted.connect(item_crafted)
	slots.append(new_slot)
	add_child(new_slot)


func calculate_all_known_recipes():
	for slot in slots:
		var recipe = Compendium.all_recipes[slot.result_item.item_name]
		if does_player_have_ingredients(recipe):
			slot.set_state_has_ingredients(true)
		else:
			slot.set_state_has_ingredients(false)


func item_crafted(item: Item):
	calculate_all_known_recipes()
	Inventory.item_crafted.emit(item)


func does_player_have_ingredients(recipe: Array[Item]):
	for item in recipe:
		if not Inventory.has_item(item.item_name, item.amount):
			return false
	return true
