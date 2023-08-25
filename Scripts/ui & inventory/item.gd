extends Resource
class_name Item

# all these fields are exported because duplicate() only copies exported fields
@export var compendium_index: int
@export var item_name: StringName
@export var value: int
@export var is_edible: bool
@export var power: int
@export var is_stackable: bool = true
@export var is_tool: bool = false
@export var is_crop: bool = false
@export var placeable_name: StringName
@export var is_placeable: bool = false

@export var amount: int = 1

func initialize(index: int, input_values: Array):
	compendium_index = index
	
	item_name = input_values[0]
	value = int(input_values[1])
	is_edible = bool(int(input_values[2]))

	power = int(input_values[3])
	
	if power > 0:
		is_stackable = false
		is_tool = true
	
	if (item_name.split("_")[-1] == StringName("seed")
	or item_name.split("_")[-1] == StringName("sapling")):
		is_crop = true
		is_placeable = true
		placeable_name = StringName(item_name.split("_")[0])
	
	if item_name.split("_")[-1] == StringName("chest"):
		is_placeable = true
		placeable_name = item_name
