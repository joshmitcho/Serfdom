#procedural_generator.gd
extends Node2D

@export var tilemap: Map
@export var entrance: MapConnector

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()


func _ready():
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()
	
	var wall_tiles = []
	var dirt_tiles = []
	
	var used_cells: Array[Vector2i] = tilemap.get_used_cells(0)
	
	var wall_threshold: int = tilemap.get_used_rect().grow(-5).size.x / 2
	
	var start_noise_value: float = altitude.get_noise_2d(0, 0)
	if start_noise_value < 0.07 and start_noise_value > -0.07:
		start_noise_value += 0.2
	
	for cell: Vector2i in used_cells:
		#encloses the map in walls
		if cell.length() > wall_threshold:
			wall_tiles.append(cell)
			continue
		
		var alt = altitude.get_noise_2d(cell.x, cell.y) + start_noise_value
		
		if abs(alt) < abs(start_noise_value) * 2:
			dirt_tiles.append(cell)
			dirt_tiles.append_array(get_all_neighbour_cells(cell))
		
		if Vector2.ZERO.distance_to(cell) > 5: # ensures no walls spawn within 5 tiles of player
			if abs(alt) < abs(start_noise_value):
				wall_tiles.append(cell)
				wall_tiles.append_array(get_all_neighbour_cells(cell))
	
	tilemap.set_cells_terrain_connect(tilemap.LAYER_NAMES.GRASS, dirt_tiles, 3, 0)
	tilemap.set_cells_terrain_connect(tilemap.LAYER_NAMES.GROUND_ITEMS, wall_tiles, 3, 1)


func get_all_neighbour_cells(cell: Vector2i):
	var neighbours = []
	for i in [0, 3, 4, 7, 8, 11, 12, 15]:
		neighbours.append(tilemap.get_neighbor_cell(cell, i))
	return neighbours
