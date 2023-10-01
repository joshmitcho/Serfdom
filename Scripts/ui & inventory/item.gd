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
@export var is_pipe: bool = false

@export var amount: int = 1

func initialize(index: int, input_values: Array):
	compendium_index = index
	
	item_name = input_values[0]
	value = int(input_values[1])
	tag = StringName(input_values[2].strip_edges())
	description = input_values[3]
	
	placeable_name = item_name
	
	if tag == StringName("tool"):
		power = Compendium.TOOL_TIERS[item_name.split("_")[0]]
		is_stackable = false
		is_tool = true
	
	if tag == StringName("crop"):
		is_crop = true
		is_placeable = true
		var split_name = item_name.split("_")
		placeable_name = StringName("_".join(split_name.slice(0, -1)))
	
	if tag == StringName("chest"):
		is_placeable = true
		is_chest = true
	
	if tag == StringName("machine"):
		is_placeable = true
		is_machine = true
	
	if tag == StringName("pipe"):
		is_placeable = true
		is_pipe = true
