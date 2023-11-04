#npc_manager.gd
extends Node

const npc_base = preload("res://Scenes/npc.tscn")
const balloon_base = preload("res://Scenes/dialogue/dialogue_box.tscn")

const DIRECTION_OFFSETS: Dictionary = {
	"up": 0, "down": 1, "left": 2, "right": 3
}

# "spritesheet_name": [h_frames, v_frames, fps] 
const ANIMATION_DATA: Dictionary = {
	"walk": [6, 4, 8.0]
}

var all_npcs: Dictionary
var all_npc_tiles: Array[Vector2i]
var player_name: String = ""
var map: TileMap
var nav_grid: AStarGrid2D


func _ready():
	TimeManager.time_tick.connect(time_tick)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func time_tick(day: int, hour: int, minute: int):
	if map == null: return
	
	if minute % 20 == 0:
		for npc_name in all_npcs:
			set_npc_move_path(npc_name, Vector2i(randi_range(20, 23), randi_range(-9, -8)))
	else:
		for npc_name in all_npcs:
			set_npc_move_path(npc_name, Vector2i(randi_range(10, 13), randi_range(-3, -1)))


func set_npc_move_path(npc_name: String, destination_tile: Vector2i, _target_time: float = 1):
	var npc: NPC = all_npcs[npc_name]
	var start_tile = map.local_to_map(npc.position)
	var move_path = nav_grid.get_point_path(start_tile, destination_tile)
	if move_path.size() > 0:
		npc.set_move_path(move_path)
		npc.state = npc.STATE.MIGRATING
		
		#for point in move_path:
			#map.set_cell(map.LAYER_NAMES.NAVIGATION, map.local_to_map(point), 0, Vector2i(5, 18))


func update_nav_grid(tile: Vector2i, solid_status: bool):
	nav_grid.set_point_solid(tile, solid_status)
	for npc_name in all_npcs:
		var npc: NPC = all_npcs[npc_name]
		if npc.state == npc.STATE.MIGRATING:
			set_npc_move_path(npc_name, map.local_to_map(npc.current_target_position))


func talk_to(npc_name: String, player_postiion: Vector2, p_map: TileMap):
	var npc: NPC = all_npcs[npc_name]
	var player_tile = p_map.local_to_map(player_postiion)
	var npc_tile = p_map.local_to_map(npc.position)
	npc.face(player_tile - npc_tile)
	if npc.state == npc.STATE.MIGRATING:
		npc.state = npc.STATE.MIGRATING_PAUSED
	start_dialogue(npc_name, TimeManager.get_time_dialogue_string())


func load_npcs(p_map: TileMap):
	var i = 0
	for npc_name in Compendium.ALL_NPCS:
		var new_npc: NPC = npc_base.instantiate()
		new_npc.npc_name = npc_name
		new_npc.position = p_map.map_to_local(Vector2i(10, -7) + Vector2i(i, 0))
		all_npcs[npc_name] = new_npc
		p_map.add_child(new_npc)
		i += 1


func initialize_navigation_grid(p_map: TileMap):
	map = p_map
	nav_grid = AStarGrid2D.new()
	nav_grid.region = map.get_used_rect()
	nav_grid.cell_size = Vector2i(16, 16)
	nav_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	nav_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	nav_grid.jumping_enabled = true
	nav_grid.update()
	
	for layer in range(map.LAYER_NAMES.WATER, map.LAYER_NAMES.NAVIGATION):
		if layer == map.LAYER_NAMES.PIPES:
			continue
		for tile in map.get_used_cells(layer):
			nav_grid.set_point_solid(tile, true)


func ask_for_name() -> void:
	var name_input_dialog = load("res://Scenes/dialogue/name_input_dialog.tscn").instantiate()
	get_tree().root.add_child(name_input_dialog)
	name_input_dialog.popup_centered()
	await name_input_dialog.confirmed
	player_name = name_input_dialog.name_edit.text
	name_input_dialog.queue_free()


func _on_dialogue_ended(_resource):
	get_tree().paused = false
	await get_tree().create_timer(1).timeout
	for npc_name in all_npcs:
		var npc: NPC = all_npcs[npc_name]
		if npc.state == npc.STATE.MIGRATING_PAUSED:
			npc.state = npc.STATE.MIGRATING


func start_dialogue(dialogue_resource_name: String, title: String):
	var balloon = balloon_base.instantiate()
	get_tree().current_scene.add_child(balloon)
	get_tree().paused = true
	balloon.start(load("res://Dialogue/" + dialogue_resource_name + ".dialogue"), title)


func test_dialogue(resource: DialogueResource, title: String):
	var balloon = balloon_base.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title)
