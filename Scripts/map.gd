# map.gd
extends TileMap
class_name Map

#signal destroyables_initialized()
signal map_exited(destination_map: StringName, destination_connector: int)

enum LAYER_NAMES {
	BASE, DUG_SOIL, WATERED_SOIL, GRASS, WATER,
	PIPES, GROUND_ITEMS, DECORATION_LOW, DECORATION_HIGH,
	NO_OBSTRUCTIONS, NAVIGATION
}

@export var map_type: Compendium.MAP_TYPE
@export var destroyable_spawn_rate: float = 1.0 / 5
@export var trees_percent: float = 0.0
@export var available_destroyables: Dictionary

const SCENE_TILES_SOURCE_ID: int = 2
const WATER_SOURCE_ID: int = 10

var connectors: Array[MapConnector]

var player: Player
var tile_aim_indicator: TextureRect
var players_held_item: Item
const GREEN_HIGHLIGHT = Color(0, 1, 0, 0.3)
const RED_HIGHLIGHT = Color(1, 0, 0, 0.3)

var destroyables: Dictionary = {}
const destroyable_base = preload("res://Scenes/ground items/destroyable.tscn")
const drop_base = preload("res://Scenes/ui & inventory/drop.tscn")


func _ready():
	set_layer_modulate(LAYER_NAMES.NO_OBSTRUCTIONS, Color.TRANSPARENT)
	for child in get_children():
		if child is MapConnector:
			connectors.append(child)
			child.map_connector_triggered.connect(_on_map_connector_triggered)


func connect_player(p_player: Player):
	player = p_player
	player.do_action_pressed.connect(do_action_pressed)
	player.place_attempted.connect(_on_player_place_attempted)
	player.tool_used.connect(_on_player_tool_used)
	player.hold_changed.connect(_on_player_hold_changed)


func scatter_destroyables() -> void:
	if map_type == Compendium.MAP_TYPE.INTERIOR or map_type == Compendium.MAP_TYPE.TOWN:
		return
	
	var cells = get_used_cells(LAYER_NAMES.BASE)
	cells.erase(local_to_map(player.position))
	
	for npc in NpcManager.all_npcs.values():
		cells.erase(local_to_map(npc.position))
	
	for i in cells.size() * destroyable_spawn_rate:
		var rand_cell_coords = cells.pick_random()
		if is_tile_empty(rand_cell_coords):
			set_cell(LAYER_NAMES.GROUND_ITEMS, rand_cell_coords, SCENE_TILES_SOURCE_ID, Vector2i.ZERO, int(randf() + trees_percent))
	initialize_destroyable_objects.call_deferred()


func initialize_destroyable_objects() -> void:
	var raw_weights: Array = available_destroyables.values()
	var total_weight: float = 0
	var weighted_odds: Array[float] = []
	
	for weight in raw_weights:
		total_weight += weight
	
	for weight: float in raw_weights:
		if weighted_odds == []:
			weighted_odds.append(weight / total_weight)
		else:
			weighted_odds.append(weighted_odds.back() + (weight / total_weight))
	
	for destroyable: Destroyable in destroyables.values():
		if destroyable is WoodTree:
			destroyable.initialize(Compendium.tree_keys.pick_random())
		else:
			var weighted_random_index = weighted_random_selection(weighted_odds)
			destroyable.initialize(available_destroyables.keys()[weighted_random_index])
		destroyable.items_dropped.connect(spawn_drops)


func do_action_pressed(offsets: Array) -> void:
	var action_tiles: Array = []
	for i in offsets.size():
		action_tiles.append(local_to_map(player.position) + offsets[i])
	
	for tile in action_tiles:
		# if you're talking to an NPC
		for npc in NpcManager.all_npcs.values():
			if local_to_map(npc.position) == tile:
				NpcManager.talk_to(npc.npc_name, player.position, self)
				return
	
		# if you're interacting with a machine/chest
		if destroyables.get(tile) != null:
			destroyables[tile].do_action()
			return


func _on_player_tool_used(tool: StringName, tool_offsets: Array, power: int) -> void:
	var tool_tiles: Array = []
	for i in tool_offsets.size():
		tool_tiles.append(local_to_map(player.position) + tool_offsets[i])
	
	if tool == StringName("shovel"):
		use_shovel(tool_tiles)
	elif tool == StringName("pail"):
		use_pail(tool_tiles)
	else:
		use_breaking_tool(tool, tool_tiles, power)


func use_shovel(tool_tiles: Array) -> void:
	for tile in tool_tiles:
		if is_tile_tillable(tile):
			if map_type == Compendium.MAP_TYPE.CAVE:
				set_cells_terrain_connect(LAYER_NAMES.DUG_SOIL, [tile], 1, 2)
			else:
				set_cells_terrain_connect(LAYER_NAMES.DUG_SOIL, [tile], 1, 0)
			SoundManager.play_pitched_sfx(Compendium.dig_sfx)
			return
	SoundManager.play_pitched_sfx(Compendium.thud_sfx)


func use_pail(tool_tiles: Array) -> void:
	var pail = Inventory.get_current_item()

	for tile in tool_tiles:
		if is_tile_over_water(tile):
			pail.power = Compendium.TOOL_TIERS[pail.item_name.split("_")[0]] + 1
			break
	
	if pail.power > 0:
		pail.power -= 1
		Inventory.items_changed.emit([Inventory.active_index])
		SoundManager.play_pitched_sfx(Compendium.watering_sfx)
		for tile in tool_tiles:
			if get_cell_source_id(LAYER_NAMES.DUG_SOIL, tile) >= 0:
				if map_type == Compendium.MAP_TYPE.CAVE:
					set_cells_terrain_connect(LAYER_NAMES.WATERED_SOIL, [tile], 1, 3)
				else:
					set_cells_terrain_connect(LAYER_NAMES.WATERED_SOIL, [tile], 1, 1)
				return


func use_breaking_tool(tool: StringName, tool_tiles: Array, power: int) -> void:
	for tile in tool_tiles:
		var destroyable: Destroyable = destroyables.get(tile)
		if destroyable == null or destroyable.is_dying:
			continue
		if tool == destroyable.compatible_tool_type:
			destroyable.take_hit(power)
			return
	if Inventory.get_current_tool_type() == StringName("sickle"):
		SoundManager.play_pitched_sfx(Compendium.sfx_swish)
	else:
		SoundManager.play_pitched_sfx(Compendium.thud_sfx)


func _on_player_place_attempted(placeable: Item, offset: Vector2i) -> void:
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
		
		NpcManager.update_nav_grid(tile, true)
		initialize_placeable_object.call_deferred(tile, placeable.placeable_name)
		Inventory.increment_item_amount(Inventory.active_index, -1)
		_on_player_hold_changed()


func initialize_placeable_object(tile: Vector2i, placeable_name: StringName) -> void:
	var placeable = destroyables[tile]
	placeable.initialize(placeable_name)
	placeable.items_dropped.connect(spawn_drops)
	if is_tile_over_water(tile):
		placeable.is_in_water = true


func new_day(_year: int, season: int) -> void:
#	grow all trees and watered crops
	for dest in destroyables.values():
		if dest is WoodTree:
			dest.grow_if_alive(season)
		elif dest is Crop:
			dest.grow_if_watered(season)
	
#	wipe all watering from previous day
	var watered_tiles = get_used_cells(LAYER_NAMES.WATERED_SOIL)
	for tile in watered_tiles:
		erase_cell(LAYER_NAMES.WATERED_SOIL, tile)
	
	irrigate()


func irrigate() -> void:
	var all_pipe_tiles = get_used_cells(LAYER_NAMES.PIPES)
#	first sever all pipe connections (except in-water pipes)	
	for tile in all_pipe_tiles:
		if not destroyables[tile].is_in_water:
			destroyables[tile].irrigate(false)
	
#	then loop through again to find an in-water pipe to start from
	for tile in all_pipe_tiles:
		if destroyables[tile].is_in_water:
			propagate_irrigation(tile, destroyables[tile])


func propagate_irrigation(tile: Vector2i, pipe: Pipe) -> void:
	pipe.irrigate(true)
	await get_tree().create_timer(0.3).timeout
	var neighbor_tiles = get_surrounding_cells(tile)
	for neighbor_tile in neighbor_tiles:
		if get_cell_source_id(LAYER_NAMES.DUG_SOIL, neighbor_tile) >= 0:
			set_cells_terrain_connect(LAYER_NAMES.WATERED_SOIL, [neighbor_tile], 1, 1)
		var neighbor_pipe = destroyables.get(neighbor_tile)
		if neighbor_pipe is Pipe and not neighbor_pipe.is_connected_to_water:
			propagate_irrigation(neighbor_tile, neighbor_pipe)


func drop_item(_i: int, item: Item) -> void:
	var drop: Drop = drop_base.instantiate()
	drop.initialize(item, get_local_mouse_position(), 0)
	spawn_drops([drop], null, false)


func spawn_drops(drops: Array[Drop], destroyable_position, remove: bool = true) -> void:
	if destroyable_position != null and remove:
		var destroyable_tile = local_to_map(destroyable_position)
		erase_cell(LAYER_NAMES.PIPES, destroyable_tile)
		erase_cell(LAYER_NAMES.GROUND_ITEMS, destroyable_tile)
		destroyables.erase(destroyable_tile)
		NpcManager.update_nav_grid(destroyable_tile, false)
	for drop in drops:
		add_child(drop)
		drop.spawn()


func _on_map_connector_triggered(destination_map: StringName, destination_connector: int):
	map_exited.emit(destination_map, destination_connector)


func _physics_process(_delta) -> void:
	var map_space_posistion = local_to_map(player.position) + player.facing
	var snapped_position = map_to_local(map_space_posistion)  + Vector2(-8, -8)
	tile_aim_indicator.position = tile_aim_indicator.position.slerp(snapped_position, 0.5)
	tile_aim_indicator.modulate = tile_aim_indicator_colour(map_space_posistion)


func tile_aim_indicator_colour(tile: Vector2i) -> Color:
	if players_held_item is Item:
		if players_held_item.is_crop:
			if is_tile_plantable(tile):
				return GREEN_HIGHLIGHT
			else:
				return RED_HIGHLIGHT
		elif players_held_item.is_placeable and is_tile_empty(tile):
			return GREEN_HIGHLIGHT
		elif players_held_item.is_pipe and is_tile_empty(tile, [LAYER_NAMES.WATER]):
			return GREEN_HIGHLIGHT
	return RED_HIGHLIGHT


func weighted_random_selection(weighted_odds: Array[float]) -> int:
	var random_value = randf()
	for i in weighted_odds.size():
		if random_value <= weighted_odds[i]:
			return i
	print("something has gone wrong")
	return 999 #something has gone wrong


func is_tile_tillable(tile_coord: Vector2i) -> bool:
	if not is_tile_empty(tile_coord):
		return false
	if get_cell_source_id(LAYER_NAMES.BASE, tile_coord) == -1:
		return false
	if get_cell_source_id(LAYER_NAMES.GRASS, tile_coord) != -1:
		return false
	if get_cell_source_id(LAYER_NAMES.DUG_SOIL, tile_coord) != -1:
		return false
	return true


func is_tile_plantable(tile_coord: Vector2i) -> bool:
	if map_type != Compendium.MAP_TYPE.FARM:
		return false
	if not is_tile_empty(tile_coord):
		return false
	if get_cell_source_id(LAYER_NAMES.DUG_SOIL, tile_coord) != 3:
		return false
	return true


func is_crop_watered(crop_position: Vector2) -> bool:
	return get_cell_source_id(LAYER_NAMES.WATERED_SOIL, local_to_map(crop_position)) == 3


func is_tile_over_water(tile: Vector2i) -> bool:
	return get_cell_source_id(LAYER_NAMES.WATER, tile) == 10


func is_tile_empty(tile_coord: Vector2i, ignored_layers: Array = []) -> bool:
	if destroyables.get(tile_coord):
		return false
	for layer in range(LAYER_NAMES.WATER, LAYER_NAMES.NAVIGATION): #doesn't include NAVIGATION
		if layer in ignored_layers:
			continue
		if get_cell_source_id(layer, tile_coord) != -1:
			return false
	return true


func _on_player_hold_changed() -> void:
	players_held_item = Inventory.get_current_item()
	if players_held_item is Item and players_held_item.is_placeable:
		tile_aim_indicator.show()
	else:
		tile_aim_indicator.hide()

