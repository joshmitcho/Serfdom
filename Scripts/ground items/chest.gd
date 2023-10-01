# chest.gd
extends Placeable
class_name Chest

@onready var item_container: ItemContainer = $ItemContainer
@onready var chest_ui: ChestUI = %ChestUI

func _ready():
	Inventory.chest_closed.connect(close_chest)
	super._ready()


func initialize(p_name: StringName = "name"):
	super.initialize(p_name)
	item_container.set_bars_unlocked(Compendium.CHEST_SIZES[object_name.split("_")[0]])


func take_hit(_power: int):
	if item_container.is_empty():
		super.die()


func do_action():
	animator.play()
	Inventory.emit_signal("chest_opened")
#	await animator.animation_finished
	Inventory.opened_chest = item_container

	chest_ui.open_chest_ui()
	

func close_chest():
	if Inventory.opened_chest == item_container:
		animator.play_backwards()
		Inventory.opened_chest = null
		chest_ui.close_chest_ui()
