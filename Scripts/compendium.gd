# compendium.gd
extends Node

const TREES_INDICES: Vector2i = Vector2i(3, 6)
const FARM_DESTROYABLES_INDICES: Vector2i = Vector2i(6, 9)
const FOREST_DESTROYABLES_INDICES: Vector2i = Vector2i(3, 8)
const MINE_DESTROYABLES_INDICES: Vector2i = Vector2i(9, 9)

var all_items: Dictionary
var all_crops: Dictionary

const items_spritesheet: Texture2D = preload("res://Art/items.png")
var num_sprites: Vector2

const thud_sfx = preload("res://SFX/woodyHit.wav")
const dig_sfx = preload("res://SFX/hoeHit.wav")
const watering_sfx = preload("res://SFX/watering.wav")
const sfx_axchop = preload("res://SFX/axchop.wav")
const sfx_axe = preload("res://SFX/axe.wav")
const sfx_tree_fell = preload("res://SFX/tree_fell.wav")
const sfx_swish = preload("res://SFX/hoe.wav")
const sfx_chop1 = preload("res://SFX/chop1.wav")
const sfx_cut = preload("res://SFX/cut.wav")
const sfx_hammer = preload("res://SFX/hammer.wav")
const sfx_brick1 = preload("res://SFX/brick1.wav")
const sfx_brick2 = preload("res://SFX/brick2.wav")
const sfx_plant_seed = [
	preload("res://SFX/plant_seed_1.wav"),
	preload("res://SFX/plant_seed_2.wav")
]
const DAY_JINGLE = preload("res://SFX/morningcrow.ogg")
const NIGHT_JINGLE = preload("res://SFX/howlingwolf.ogg")
const DAY_SOUNDSCAPE = preload("res://SFX/nature-soundscape.ogg")
const NIGHT_SOUNDSCAPE = preload("res://SFX/creepy-soundscape.ogg")

const TOOL_TIERS: Dictionary = {
	rusty = 10,
	bronze = 14,
	steel = 19,
	adamant = 24,
	mithril = 30
}

const CHEST_SIZES: Dictionary = {
	crude = 1,
	improved = 2,
	deluxe = 3
}

const ALL_NPCS: Dictionary = {
	bloom = [
		"serf", 1.5
	],
	clyne = [
		"serf", 0.8
	],
	daru = [
		"monarchy", 0.6
	],
	swain = [
		"serf", 1.4
	],
	wilfred = [
		"serf", 1.6
	]
}

const all_destroyables: Dictionary = {
	stump_0 = [
		"axe", 20,
		sfx_axchop, [sfx_axe],
		2.5, ["wood"],
		-16
	],
	stump_1 = [
		"axe", 30,
		sfx_axchop, [sfx_axe],
		3.5, ["wood"],
		-16
	],
	stump_2 = [
		"axe", 50,
		sfx_axchop, [sfx_axe],
		4.5, ["wood"],
		-16
	],
	tree_0 = [
		"axe", 30,
		sfx_axchop, [sfx_axe],
		4.5, ["wood"],
		-16
	],
	tree_1 = [
		"axe", 50,
		sfx_axchop, [sfx_axe],
		6.5, ["wood"],
		-16
	],
	tree_2 = [
		"axe", 100,
		sfx_axchop, [sfx_tree_fell],
		9.5, ["wood"],
		-16
	],
	stick = [
		"axe", 10,
		sfx_chop1, [sfx_axchop],
		1.0, ["wood"],
		0
	],
	grass = [
		"sickle", 10,
		sfx_swish, [sfx_cut],
		1.15, ["fibre"],
		0
	],
	rock_small = [
		"hammer", 10,
		sfx_hammer, [sfx_brick1, sfx_brick2],
		1.25, ["stone", "stone", "stone", "stone", "stone", "stone", "stone", "coal"],
		0
	]
}

var tree_keys = all_destroyables.keys().slice(TREES_INDICES.x, TREES_INDICES.y)
var farm_destroyable_keys = all_destroyables.keys().slice(FARM_DESTROYABLES_INDICES.x, FARM_DESTROYABLES_INDICES.y)
var forest_destroyable_keys = all_destroyables.keys().slice(FOREST_DESTROYABLES_INDICES.x, FOREST_DESTROYABLES_INDICES.y)
var mine_destroyable_keys = all_destroyables.keys().slice(MINE_DESTROYABLES_INDICES.x, MINE_DESTROYABLES_INDICES.y)

func _ready():
	_load_items_from_csv()
	_load_crops_from_csv()


func _load_items_from_csv():
	num_sprites = items_spritesheet.get_size() / Vector2(16, 16)
	
	var file = FileAccess.open("res://Data/Serfdom - items.csv", FileAccess.READ)
	var content = file.get_as_text().strip_edges().split('\n').slice(1)
	
	var i: int = 0
	for line in content:
		var item_data = line.split(',')
		var new_item = Item.new()
		new_item.initialize(i, item_data)
		all_items[new_item.item_name] = new_item
		i += 1


func _load_crops_from_csv():
	var file = FileAccess.open("res://Data/Serfdom - crops.csv", FileAccess.READ)
	var content = file.get_as_text().strip_edges().split('\n').slice(1)
	
	for line in content:
		var crop_data = line.split(',')
		all_crops[crop_data[0]] = [
			float(crop_data[1]),
			int(crop_data[2]),
			int(crop_data[3]),
			int(crop_data[4]),
			int(crop_data[5]),
			int(crop_data[6])
		]
