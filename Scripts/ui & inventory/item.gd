extends Resource
class_name Item

# all these fields are exported because duplicate() only copies exported fields
@export var compendium_index: int
@export var item_name: StringName
@export var value: int
@export var is_edible: bool
@export var power: int = 0
@export var tag: StringName
@export var description: String
@export var is_stackable: bool = true
@export var is_tool: bool = false
@export var is_crop: bool = false
@export var placeable_name: StringName
@export var is_placeable: bool = false
@export var is_chest: bool = false
@export var is_machine: bool = false

@export var amount: int = 1

func initialize(index: int, input_values: Array):
	compendium_index = index
	
	item_name = input_values[0]
	value = int(input_values[1])
	tag = StringName(input_values[2].strip_edges())
	description = input_values[3]
	
	if tag == StringName("tool"):
		power = Compendium.TOOL_TIERS[item_name.split("_")[0]]
		is_stackable = false
		is_tool = true
	
	if tag == StringName("crop"):
		is_crop = true
		is_placeable = true
		placeable_name = StringName(item_name.split("_")[0])
	
	if tag == StringName("chest"):
		is_placeable = true
		is_chest = true
		placeable_name = item_name
		
	if tag == StringName("machine"):
		is_placeable = true
		is_machine = true
		placeable_name = item_name
