# map.gd
extends TileMap

enum LAYER_NAMES {BASE, DUG_SOIL, WATERED_SOIL, GRASS, WATER, PIPES, GROUND_ITEMS, DECORATION_LOW, DECORATION_HIGH}
const SCENE_TILES_SOURCE_ID: int = 2
const WATER_SOURCE_ID: int = 10
const GROUND_ITEMS_SPAWN_RATE: float = 1.0 / 50
const TREES_PERCENT: float = 0.3

@onready var player: Player = %Player

@onready var tile_aim_indicator = $TileAimIndicator
var current_held_item: Item
const GREEN_HIGHLIGHT = Color("00ff0050")
const RED_HIGHLIGHT = Color("ff000050")

var destroyables: Dictionary = {}
const destroyable_base = preload("res://Scenes/ground items/destroyable.tscn")
const drop_base = preload("res://Scenes/ui & inventory/drop.tscn")

@onready var day_night_cycle = %DayNightCycle
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
	
	set_destroyable_cells()
	time_money_ui.set_money.call_deferred(Inventory.money_supply)


func set_destroyable_cells():
	var cells = get_used_cells(LAYER_NAMES.BASE)
	cells.erase(local_to_map(player.position))
	
	for i in cells.size() * GROUND_ITEMS_SPAWN_RATE:
		var rand_cell_coords = cells.pick_random()
		if is_tile_empty(rand_cell_coords):
			set_cell(LAYER_NAMES.GROUND_ITEMS, rand_cell_coords, SCENE_TILES_SOURCE_ID, Vector2i.ZERO, int(randf() + TREES_PERCENT))
	initialize_destroyables.call_deferred(Compendium.farm_destroyable_keys, Compendium.tree_keys)


func initialize_destroyables(names: Array, tree_names: Array):
	for destroyable in destroyables.values():
		if destroyable is WoodTree:
			destroyable.initialize(tree_names.pick_random())
		else:
			destroyable.initialize(names.pick_random())
		destroyable.items_dropped.connect(spawn_drops)

func do_action_pressed(offsets: Array):
	var action_tiles: Array = []
	for i in offsets.size():
		action_tiles.append(local_to_map(player.position) + offsets[i])
	
	for tile in action_tiles:
		# if you're talking to an NPC
		#for npc in NPCs: ...
	
		# if you're interacting with a machine/chest
		if tile in destroyables:
			destroyables[tile].do_action()
			return

func _on_player_tool_used(tool: StringName, tool_offsets: Array, power: int):
	var tool_tiles: Array = []
	for i in tool_offsets.size():
		tool_tiles.append(local_to_map(player.position) + tool_offsets[i])
	
	if tool == StringName("shovel"):
		use_shovel(tool_tiles)
	elif tool == StringName("pail"):
		use_pail(tool_tiles)
	else:
		use_breaking_tool(tool, tool_tiles, power)


func use_shovel(tool_tiles: Array):
	for tile in tool_tiles:
		if is_tile_tillable(tile):
			set_cells_terrain_connect(LAYER_NAMES.DUG_SOIL, [tile], 1, 0)
			sfx_player.set_stream(dig_sfx)
			sfx_player.play()
			return
	play_whiff_sound()


func use_pail(tool_tiles: Array):
	var pail = Inventory.get_current_item()

	for tile in tool_tiles:
		if is_tile_over_water(tile):
			pail.power = Compendium.TOOL_TIERS[pail.item_name.split("_")[0]] + 1
			break
	
	if pail.power > 0:
		pail.power -= 1
		Inventory.emit_signal("items_changed", [Inventory.active_index])
		sfx_player.set_stream(watering_sfx)
		sfx_player.play()
		for tile in tool_tiles:
			if get_cell_source_id(LAYER_NAMES.DUG_SOIL, tile) >= 0:
				set_cells_terrain_connect(LAYER_NAMES.WATERED_SOIL, [tile], 1, 1)
				return


func use_breaking_tool(tool: StringName, tool_tiles: Array, power: int):
	for tile in tool_tiles:
		if tile in destroyables:
			var destroyable = destroyables[tile]
			if destroyable.is_dying:
				continue
			if tool == destroyable.compatible_tool_type:
				destroyable.take_hit(power)
				return
	play_whiff_sound()


func _on_player_place_attempted(placeable: Item, offset: Vector2i):
	var tile = local_to_map(player.position) + offset
	
	if tile_aim_indicator.modulate == GREEN_HIGHLIGHT:
		if placeable.is_crop:
			set_cell(LAYER_NAMES.GROUND_ITEMS, tile, SCENE_TILES_SOURCE_ID, Vector2i.ZERO, 2)
		elif placeable.is_chest:
			set_cell(LAYER_NAMES.GROUND_ITEMS, tile, SCENE_TILES_SOURCE_ID, Vector2i.ZERO, 3)
		elif placeable.is_machine:
			set_cell(LAYER_NAMES.GROUND_ITEMS, tile, SCENE_TILES_SOURCE_ID, Vector2i.ZERO, 4)
		elif placeable.is_pipe:
			set_cell(LAYER_NAMES.GROUND_ITEMS, tile, SCENE_TILES_SOURCE_ID, Vector2i.ZERO, 5)
			set_cells_terrain_connect(LAYER_NAMES.PIPES, [tile], 2, 0)
		
		initialize_placeable.call_deferred(tile, placeable.placeable_name)
		Inventory.increment_item_amount(Inventory.active_index, -1)
		_on_player_hold_changed()


func initialize_placeable(tile: Vector2i, placeable_name: StringName):
	var placeable = destroyables[tile]
	placeable.initialize(placeable_name)
	placeable.items_dropped.connect(spawn_drops)
	if is_tile_over_water(tile):
		placeable.is_in_water = true


func irrigate():
	var all_pipe_tiles = get_used_cells(LAYER_NAMES.PIPES)
#	first sever all pipe connections (except in-water pipes)	
	for tile in all_pipe_tiles:
		if not destroyables[tile].is_in_water:
			destroyables[tile].irrigate(false)
	
#	then loop through again to find an in-water pipe to start from
	for tile in all_pipe_tiles:
		if destroyables[tile].is_in_water:
			propagate_irrigation(tile, destroyables[tile])
			


func propagate_irrigation(tile: Vector2i, pipe: Pipe):
	pipe.irrigate(true)
	var neighbor_tiles = get_surrounding_cells(tile)
	for neighbor_tile in neighbor_tiles:
		if get_cell_source_id(LAYER_NAMES.DUG_SOIL, neighbor_tile) >= 0:
			set_cells_terrain_connect(LAYER_NAMES.WATERED_SOIL, [neighbor_tile], 1, 1)
		if neighbor_tile in destroyables:
			var neighbor_pipe = destroyables[neighbor_tile]
			if neighbor_pipe is Pipe and not neighbor_pipe.is_connected_to_water:
				propagate_irrigation(neighbor_tile, neighbor_pipe)


func drop_item(_i: int, item: Item):
	var drop: Drop = drop_base.instantiate()
	drop.initialize(item, get_local_mouse_position(), 0)
	spawn_drops([drop], null, false)


func spawn_drops(drops: Array[Drop], destroyable_position, remove: bool = true):
	if destroyable_position != null and remove:
		var tile_position = local_to_map(destroyable_position)
		erase_cell(LAYER_NAMES.PIPES, tile_position)
		erase_cell(LAYER_NAMES.GROUND_ITEMS, tile_position)
		destroyables.erase(tile_position)
	for drop in drops:
		add_child(drop)
		drop.spawn()


func _physics_process(_delta):
	var map_space_posistion = local_to_map(player.position) + player.facing
	var snapped_position = map_to_local(map_space_posistion)  + Vector2(-8, -8)
	tile_aim_indicator.position = tile_aim_indicator.position.slerp(snapped_position, 0.5)
	tile_aim_indicator.modulate = tile_aim_indicator_colour(map_space_posistion)
	
	if Input.is_action_just_pressed("shift_toolbar"):
		irrigate()


func tile_aim_indicator_colour(tile: Vector2i):
	if is_instance_of(current_held_item, Item):
		if current_held_item.is_crop:
			if is_tile_plantable(tile):
				return GREEN_HIGHLIGHT
			else:
				return RED_HIGHLIGHT
		elif current_held_item.is_placeable and is_tile_empty(tile):
			return GREEN_HIGHLIGHT
		elif current_held_item.is_pipe and is_tile_empty(tile, [LAYER_NAMES.WATER]):
			return GREEN_HIGHLIGHT
	return RED_HIGHLIGHT


func is_tile_tillable(tile_coord: Vector2i):
	if not is_tile_empty(tile_coord):
		return false
	if get_cell_source_id(LAYER_NAMES.BASE, tile_coord) == -1:
		return false
	if get_cell_source_id(LAYER_NAMES.GRASS, tile_coord) != -1:
		return false
	if get_cell_source_id(LAYER_NAMES.DUG_SOIL, tile_coord) != -1:
		return false
	return true


func is_tile_plantable(tile_coord: Vector2i):
	if not is_tile_empty(tile_coord):
		return false
	if get_cell_source_id(LAYER_NAMES.DUG_SOIL, tile_coord) != 3:
		return false
	return true


func is_tile_watered(crop_position: Vector2):
	return get_cell_source_id(LAYER_NAMES.WATERED_SOIL, local_to_map(crop_position)) == 3


func is_tile_over_water(tile: Vector2i):
	return get_cell_source_id(LAYER_NAMES.WATER, tile) == 10


func is_tile_empty(tile_coord: Vector2i, ignored_layers: Array = []):
	if tile_coord in destroyables:
		return false
	for layer in range(LAYER_NAMES.WATER, LAYER_NAMES.keys().size()):
		if layer in ignored_layers:
			continue
		if get_cell_source_id(layer, tile_coord) != -1:
			return false
	return true


func _on_player_hold_changed():
	current_held_item = Inventory.get_current_item()
	if is_instance_of(current_held_item, Item) and current_held_item.is_placeable:
		tile_aim_indicator.visible = true
	else:
		tile_aim_indicator.visible = false


func play_whiff_sound():
	if Inventory.get_current_tool_type() == StringName("sickle"):
		sfx_player.set_stream(swish_sfx)
	else:
		sfx_player.set_stream(thud_sfx)
	sfx_player.play()
