# player.gd

extends CharacterBody2D
class_name Player

signal tool_used(tool: String, offset: Array, power: int)
signal place_attempted(placeable: Item, offsets: Array)
signal item_picked_up(item: Item, amount: int)
signal hold_changed()
signal current_energy_changed(new_current_energy: int)
signal max_energy_changed(new_max_energy: int)

var linear_movement_speed: int = 90
var diagonal_movement_speed: int = 60
var facing: Vector2i
var holding: String = ""

var sfx_pitches: Array = [0.943874, 1.0, 1.059463, 1.122455, 1.33484]
var sfx_index: int = 0

var max_energy: int = 270
var current_energy: int = max_energy

@onready var animator = %SpriteAnimator
@onready var tool_animator = %ToolAnimator
@onready var hold_sprite: ShadowSprite = %HoldSprite

func _ready():
	#knock position verrry slightly off-grid to prevent flickering while moving
	position += Vector2(0.003, 0.003)
	
	Inventory.items_changed.connect(new_active_item)
	Inventory.active_slot_changed.connect(new_active_item)
	
	hold_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites, Vector2i(0, 2))
	end_hold()
	
	emit_signal("max_energy_changed", max_energy)
	emit_signal("current_energy_changed", current_energy)


func on_tool_used(tool: String, offset: Array, power: int):
	emit_signal("tool_used", tool, offset, power)
	current_energy -= 2
	emit_signal("current_energy_changed", current_energy)


func _on_place_attempted(placeable: Item, offsets):
	emit_signal("place_attempted", placeable, offsets)


func _physics_process(_delta):
	var overlapping_areas: Array = $MagnetismArea.get_overlapping_areas()
	for area in overlapping_areas:
		if (is_instance_of(area, Drop) and area.pickupable
		and Inventory.does_inventory_have_room(area.item)):
			area.set_gravity_center(position)
	
	overlapping_areas = $PickupArea.get_overlapping_areas()
	for area in overlapping_areas:
		if (is_instance_of(area, Drop) and area.pickupable
		and Inventory.does_inventory_have_room(area.item)):
			drop_picked_up(area.item)
			area.queue_free()


func drop_picked_up(item: Item):
	$PopSFXPlayer.set_pitch_scale(sfx_pitches[sfx_index])
	$PopSFXPlayer.play()
	if sfx_index < sfx_pitches.size() - 1:
		sfx_index += 1
	else:
		sfx_pitches.shuffle()
		sfx_index = 0
	Inventory.add_items_to_inventory(item, item.amount)
	emit_signal("item_picked_up", item, item.amount)
	Inventory.update_money_supply(item.value)


func new_active_item(_index):
	var active_item: Item = Inventory.get_current_item()
	if not is_instance_of(active_item, Item):
		end_hold()
		return
	if active_item.is_placeable:
		start_hold(active_item)
	else:
		end_hold()
	emit_signal("hold_changed")


func start_hold(item: Item):
	holding = "hold_"
	hold_sprite.visible = true
	hold_sprite.change_frame(item.compendium_index)


func end_hold():
	holding = ""
	hold_sprite.visible = false

