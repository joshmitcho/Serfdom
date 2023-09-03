# chest.gd
extends Placeable
class_name Chest

@onready var item_container: ItemContainer = $ItemContainer
@onready var chest_ui: ChestUI = %ChestUI

func _ready():
	Inventory.chest_closed.connect(close_chest)
	super._ready()


func take_hit(_power: int):
	if item_container.is_empty():
		super.die()


func do_action():
	Inventory.opened_chest = item_container
	Inventory.emit_signal("chest_opened")
	chest_ui.open_chest_ui()
	

func close_chest():
	Inventory.opened_chest = null
	chest_ui.close_chest_ui()
