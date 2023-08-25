# map.gd
extends TileMap

enum LAYER_NAMES {BASE_LAYER, GRASS, WATERED_SOIL, GROUND_ITEMS, DECORATION_LOW, DECORATION_HIGH, WATER}
const GROUND_ITEMS_SOURCE_ID: int = 2
const GROUND_ITEMS_SPAWN_RATE: float = 1.0 / 5

@onready var player: Player = %Player

@onready var tile_aim_indicator = $TileAimIndicator
var current_held_item: Item
const GREEN_HIGHLIGHT = Color("00ff0050")
const RED_HIGHLIGHT = Color("ff000050")

var destroyables: Array = []
const destroyable_base = preload("res://Scenes/destroyable.tscn")
const drop_base = preload("res://Scenes/drop.tscn")

@onready var canvas_modulate = %CanvasModulate
@onready var time_money_ui = %TimeMoneyUI
@onready var sound_machine = %SoundMachine

@onready var sfx_player: AudioStreamPlayer = %AudioStreamPlayer
const thud_sfx = preload("res://SFX/woodyHit.wav")
const swish_sfx = preload("res://SFX/hoe.wav")
const dig_sfx = preload("res://SFX/hoeHit.wav")
const watering_sfx = preload("res://SFX/watering.wav")

func _ready():
	randomize()
	
	Inventory.money_supply_changed.connect(time_money_ui.set_money)
	Inventory.item_dropped.connect(drop_item)
	
	var cells = get_used_cells(LAYER_NAMES.BASE_LAYER)
	cells.erase(local_to_map(player.position))
	for i in cells.size() * GROUND_ITEMS_SPAWN_RATE:
		var rand_cell_coords = cells.pick_random()
		if is_tile_empty(rand_cell_coords):
			set_cell(LAYER_NAMES.GROUND_ITEMS, rand_cell_coords, GROUND_ITEMS_SOURCE_ID, Vector2i.ZERO, 0)
	
	load_destroyables.call_deferred(Compendium.farm_destroyable_keys, 0.75)


func load_destroyables(names: Array, trees_percent: float = 0.0):
	var split_index = int(destroyables.size() * trees_percent)
	initialize_destroyables(names, destroyables.slice(0, split_index))
	initialize_destroyables(Compendium.tree_keys, destroyables.slice(split_index), "stump")


func initialize_destroyables(names: Array, dest: Array, second_stage: String = ""): 
	var index: int = 0
	for i in names.size():
		while index < dest.size() / (names.size() / (i+1.0)):
			var object = dest[index]
			object.initialize(names[i])
			object.destroyed.connect(spawn_drops)
			if second_stage != "": # Add stump destroyable if it's a tree
				var growth_stage = names[i].right(2)
				var second_object = destroyable_base.instantiate()
				second_object.position = object.position
				add_child(second_object)
				move_child(second_object, index)
				second_object.initialize(second_stage + growth_stage)
				second_object.destroyed.connect(spawn_drops)
				second_object.scale = object.scale
			index += 1


func _on_player_tool_used(tool: StringName, tool_offsets: Array, power: int):
	var tool_tiles: Array = []
	for i in tool_offsets.size():
		tool_tiles.append(local_to_map(player.position) + tool_offsets[i])
	
	if tool == StringName("shovel"):
		use_shovel(tool_tiles)
	elif tool == StringName("pail"):
		use_pail(tool_tiles)
	else:
		use_other_tool(tool, tool_tiles, power)


func use_shovel(tool_tiles: Array):
	if not is_tile_empty(tool_tiles[0]):
		play_whiff_sound()
		return
	tool_tiles.reverse()
	for tile in tool_tiles:
		if is_tile_tillable(tile):
			set_cells_terrain_connect(LAYER_NAMES.GRASS, [tile], 1, 0)
			sfx_player.set_stream(dig_sfx)
			sfx_player.play()
			return
	play_whiff_sound()


func use_pail(tool_tiles: Array):
	sfx_player.set_stream(watering_sfx)
	sfx_player.play()
	tool_tiles.reverse()
	for tile in tool_tiles:
		if (get_cell_source_id(LAYER_NAMES.GRASS, tile) == 3
		and get_cell_source_id(LAYER_NAMES.WATERED_SOIL, tile) != 3):
			set_cells_terrain_connect(LAYER_NAMES.WATERED_SOIL, [tile], 1, 1)
			return


func use_other_tool(tool: StringName, tool_tiles: Array, power: int):
	for tile in tool_tiles:
		for destroyable in destroyables:
			if local_to_map(destroyable.position) == tile:
				if destroyable.is_dying:
					continue
				if tool == destroyable.compatible_tool_type:
					destroyable.take_hit(power)
					return
	play_whiff_sound()


func play_whiff_sound():
	if Inventory.get_current_tool_type() == StringName("sickle"):
		sfx_player.set_stream(swish_sfx)
	else:
		sfx_player.set_stream(thud_sfx)
	sfx_player.play()


func _on_player_place_attempted(placeable: Item, offsets):
	var tile = local_to_map(player.position) + offsets[0]
	if placeable.is_crop:
		if is_tile_plantable(tile):
	#		print("-----\nbefore: ", destroyables[-1].object_name, " ", destroyables[-1])
			set_cell(LAYER_NAMES.GROUND_ITEMS, tile, GROUND_ITEMS_SOURCE_ID, Vector2i.ZERO, 1)
			initialize_placeable.call_deferred(placeable.placeable_name)
			Inventory.update_item_amount(Inventory.active_index, -1)
	elif is_tile_empty(tile):
		set_cell(LAYER_NAMES.GROUND_ITEMS, tile, GROUND_ITEMS_SOURCE_ID, Vector2i.ZERO, 3)
		initialize_placeable.call_deferred(placeable.placeable_name)
		Inventory.update_item_amount(Inventory.active_index, -1)

func initialize_placeable(placeable_name: StringName):
#	var crops = Utils.get_children_of_type(self, Crop)
	var object = destroyables[-1]
#	print("after: ", object.object_name, " ", object)
	object.initialize(placeable_name)
	object.destroyed.connect(spawn_drops)


func drop_item(_i: int, item: Item):
	var drop: Drop = drop_base.instantiate()
	drop.initialize(item, get_local_mouse_position(), 0)
	spawn_drops([drop])


func spawn_drops(drops: Array[Drop], destroyable_position: Vector2 = Vector2(999, 999)):
	if destroyable_position != Vector2(999, 999):
		set_cell(LAYER_NAMES.GROUND_ITEMS, local_to_map(destroyable_position), -1)
		erase_cell(LAYER_NAMES.GROUND_ITEMS, local_to_map(destroyable_position))
#		print("removed")
	for drop in drops:
		add_child(drop)
		drop.spawn()


func _physics_process(_delta):
	var map_space_posistion = local_to_map(player.position) + player.facing
	var snapped_position = map_to_local(map_space_posistion)  + Vector2(-8, -8)
	tile_aim_indicator.position = tile_aim_indicator.position.slerp(snapped_position, 0.5)
	
	if is_instance_of(current_held_item, Item) and is_tile_empty(local_to_map(player.position)):
		if current_held_item.is_crop:
			if is_tile_plantable(map_space_posistion):
				tile_aim_indicator.modulate = GREEN_HIGHLIGHT
			else:
				tile_aim_indicator.modulate = RED_HIGHLIGHT
		elif current_held_item.is_placeable and is_tile_empty(map_space_posistion):
			tile_aim_indicator.modulate = GREEN_HIGHLIGHT
		else:
			tile_aim_indicator.modulate = RED_HIGHLIGHT
	else:
		tile_aim_indicator.modulate = RED_HIGHLIGHT


func is_tile_tillable(tile_coord: Vector2i):
	if not is_tile_empty(tile_coord):
		return false
	if get_cell_source_id(LAYER_NAMES.BASE_LAYER, tile_coord) == -1:
		return false
	if get_cell_source_id(LAYER_NAMES.GRASS, tile_coord) != -1:
		return false
	return true


func is_tile_plantable(tile_coord: Vector2i):
	if not is_tile_empty(tile_coord):
		return false
	if get_cell_source_id(LAYER_NAMES.GRASS, tile_coord) != 3:
		return false
	return true


func is_tile_watered(crop_position: Vector2):
	return get_cell_source_id(LAYER_NAMES.WATERED_SOIL, local_to_map(crop_position)) == 3


func is_tile_empty(tile_coord: Vector2i):
	for dest in destroyables:
		if local_to_map(dest.position) == tile_coord:
			return false
	for i in range(LAYER_NAMES.GROUND_ITEMS, LAYER_NAMES.keys().size()):
		if get_cell_source_id(i, tile_coord) != -1:
			return false
	return true


func _on_player_hold_changed():
	current_held_item = Inventory.get_current_item()
	if Inventory.get_current_item().is_placeable:
		tile_aim_indicator.visible = true
	else:
		tile_aim_indicator.visible = false
