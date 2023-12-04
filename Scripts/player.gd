# player.gd

extends CharacterBody2D
class_name Player

signal tool_used(tool: String, offset: Array, power: int)
signal place_attempted(placeable: Item, offset: Vector2i)
signal do_action_pressed(offsets: Array)

signal item_picked_up(item: Item, amount: int)
signal hold_changed()

signal current_energy_changed(new_current_energy: int)
signal max_energy_changed(new_max_energy: int)

signal hotbar_to_top()
signal hotbar_to_bottom()

var linear_movement_speed: int = 90
var diagonal_movement_speed: int = 60
var facing: Vector2i = Vector2i(0, 1)
var holding: String = ""

var sfx_pitches: Array = [0.943874, 1.0, 1.059463, 1.122455, 1.33484]
var sfx_index: int = 0

var max_energy: int = 270
var current_energy: int = max_energy

@export var map: TileMap
@export var camera: Camera2D

@onready var player_shadow = $PlayerShadow
@onready var animator = %SpriteAnimator
@onready var tool_animator = %ToolAnimator
@onready var hold_sprite: ShadowedSprite = %HoldSprite
@onready var magnetism_area: Area2D = $MagnetismArea
@onready var pickup_area: Area2D = $PickupArea


func _ready():
	Inventory.items_changed.connect(new_active_item)
	Inventory.active_slot_changed.connect(new_active_item)
	
	hold_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites, Vector2i(0, 2))
	end_hold()
	
	max_energy_changed.emit(max_energy)
	current_energy_changed.emit(current_energy)


func _on_tool_used(tool: String, offset: Array, power: int):
	tool_used.emit(tool, offset, power)
	current_energy -= 2
	current_energy_changed.emit(current_energy)


func _on_place_attempted(placeable: Item, offset: Vector2i):
	place_attempted.emit(placeable, offset)


func _on_do_action_pressed(offsets: Array):
	do_action_pressed.emit(offsets)


func _physics_process(_delta):
	player_shadow.self_modulate = DayNightModulate.shadow_modulate
	
	if position.y - camera.get_screen_center_position().y > 30:
		hotbar_to_top.emit()
	elif position.y - camera.get_screen_center_position().y < 2:
		hotbar_to_bottom.emit()
	
	var overlapping_areas: Array = magnetism_area.get_overlapping_areas()
	for area in overlapping_areas:
		if (area is Drop and area.pickupable
		and Inventory.does_container_have_room(area.item)):
			area.set_gravity_center(position)
	
	overlapping_areas = pickup_area.get_overlapping_areas()
	for area in overlapping_areas:
		if (area is Drop and area.pickupable
		and Inventory.does_container_have_room(area.item)):
			drop_picked_up(area.item)
			area.queue_free()


func drop_picked_up(item: Item):
	SoundManager.play_pitched_sfx(Compendium.sfx_pop, sfx_pitches[sfx_index])
	if sfx_index < sfx_pitches.size() - 1:
		sfx_index += 1
	else:
		sfx_pitches.shuffle()
		sfx_index = 0
	Inventory.add_item(item, item.amount)
	item_picked_up.emit(item, item.amount)


func new_active_item(_index):
	var active_item: Item = Inventory.get_current_item()
	if not active_item is Item:
		end_hold()
		return
	if active_item.is_placeable:
		start_hold(active_item)
	else:
		end_hold()
	hold_changed.emit()


func start_hold(item: Item):
	holding = "hold_"
	hold_sprite.show()
	hold_sprite.change_frame(item.compendium_index)


func end_hold():
	holding = ""
	hold_sprite.hide()
