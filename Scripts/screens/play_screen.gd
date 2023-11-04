# play_screen.gd
extends Node2D
class_name Play_Screen

@onready var map = $Map
@onready var time_money_ui = %TimeMoneyUI


func _ready():
	randomize()
	Inventory.money_supply_changed.connect(time_money_ui.set_money)
	Inventory.item_dropped.connect(map.drop_item)
	TimeManager.new_day.connect(map.new_day)
	NpcManager.load_npcs(map)
	map.scatter_destroyables()
	await map.destroyables_initialized
	NpcManager.initialize_navigation_grid(map)
	time_money_ui.set_money(Inventory.money_supply)

