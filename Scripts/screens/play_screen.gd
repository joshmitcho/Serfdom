# play_screen.gd
extends Node2D
class_name PlayScreen

signal map_initialized()

@onready var camera: Camera2D = $Camera2D
@onready var player: Player = %Player
@onready var map: Map = $Farm
@onready var tile_aim_indicator: TextureRect = %TileAimIndicator
@onready var time_money_ui: Control = %TimeMoneyUI
@onready var fade: ColorRect = $UI/Fade

#knock player position verrry slightly off-grid to prevent flickering while moving
const NUDGE: Vector2 = Vector2(0.003, 0.003)
const FADE_TIME: float = 0.3

static var current_map_type: Compendium.MAP_TYPE

func _ready():
	randomize()
	Inventory.money_supply_changed.connect(time_money_ui.set_money)
	initialize_map(map)
	time_money_ui.set_money(Inventory.money_supply)
	current_map_type = map.map_type


func switch_map(new_map_path: String, destination_connector: int):
	var new_map: Map = ResourceLoader.load_threaded_get(new_map_path).instantiate()
	add_child.call_deferred(new_map)
	initialize_map.call_deferred(new_map)
	await map_initialized
	
	for connector in new_map.connectors:
		if connector.connector_number == destination_connector:
			var rotated_exit_point: Vector2 = connector.exit_point.position.rotated(connector.rotation)
			player.position = connector.position + rotated_exit_point + NUDGE
	
	map.queue_free()
	map = new_map
	current_map_type = map.map_type
	if current_map_type == Compendium.MAP_TYPE.CAVE:
		SoundManager.play_soundscape(Compendium.CAVE_SOUNDSCAPE, 0)
	else:
		TimeManager.play_soundscapes()
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "modulate", Color.TRANSPARENT, FADE_TIME * 2)


func initialize_map(new_map: Map):
	set_camera_limits(new_map.get_used_rect(), 1)
	player.position += NUDGE
	Inventory.item_dropped.connect(new_map.drop_item)
	TimeManager.new_day.connect(new_map.new_day)
	new_map.map_exited.connect(change_map)
	new_map.connect_player(player)
	new_map.tile_aim_indicator = tile_aim_indicator
	NpcManager.load_npcs(new_map)
	new_map.scatter_destroyables()
	NpcManager.initialize_navigation_grid(new_map)
	map_initialized.emit()


func change_map(new_map_name: StringName, destination_connector: int):
	var new_map_path = "res://Maps/" + new_map_name + ".tscn"
	ResourceLoader.load_threaded_request(new_map_path)
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "modulate", Color.WHITE, FADE_TIME)
	tween.tween_callback(switch_map.bind(new_map_path, destination_connector))
	

func set_camera_limits(used_rect: Rect2i, shrink: int):
	camera.limit_left = (used_rect.position.x + shrink) * 16
	camera.limit_right = (used_rect.end.x - shrink) * 16
	camera.limit_top = (used_rect.position.y + shrink) * 16
	camera.limit_bottom = (used_rect.end.y - shrink) * 16
