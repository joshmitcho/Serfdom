# destroyable.gd
extends Area2D
class_name Destroyable

signal items_dropped(drops: Array[Drop], position: Vector2)

var object_name: StringName = "uninitialized_destroyable"
var compatible_tool_type: StringName = "none"
var starting_health: int = 1
var total_damage: int = 0

var drops: Array[Drop]
var drop_types: Array
var num_drops: int
var drop_offsets: Array = [-4, 4, 0, -8, 8, 0, -12, 12, -16, 16, -20, 20]

var is_dying: bool = false
var die_sfx: Array = []
var hit_sfx
var sfx_pitches: Array = [0.8, 0.943874, 1.0, 1.059463, 1.122455]
var sfx_index: int = 0

var animator: AnimatedSprite2D
var shadow_animator: AnimatedSprite2D
var shake_tween


func _ready():
	shake_tween = get_node_or_null("ShakeTween")
	if get_node_or_null("ShadowAnimatedSprite"):
		shadow_animator = $ShadowAnimatedSprite
		animator = %MainAnimatedSprite
	else:
		shadow_animator = AnimatedSprite2D.new()
		animator = $AnimatedSprite2D
	var parent_map: TileMap = get_parent()
	parent_map.destroyables[parent_map.local_to_map(self.position)] = self
	scale = Vector2([1, -1].pick_random(), 1)

func initialize(p_name: StringName = "name"):
	sfx_pitches.shuffle()
	object_name = p_name
	animator.animation = object_name
	shadow_animator.animation = object_name
	
	compatible_tool_type = Compendium.all_destroyables[object_name][0]
	starting_health = Compendium.all_destroyables[object_name][1]
	
	hit_sfx = Compendium.all_destroyables[object_name][2]
	die_sfx = Compendium.all_destroyables[object_name][3]
	
	var drop_odds = Compendium.all_destroyables[object_name][4]
	num_drops = int(drop_odds)
	if randf_range(0, 1) < (drop_odds - num_drops):
		num_drops += 1
	drop_types  = Compendium.all_destroyables[object_name][5]
	
	animator.modulate = Color.WHITE
	animator.offset.y = Compendium.all_destroyables[object_name][6]
	shadow_animator.offset.y = Compendium.all_destroyables[object_name][6]


func _physics_process(_delta):
	shadow_animator.self_modulate = DayNightModulate.shadow_modulate


func play_pitched_sfx(sfx):
	SoundManager.play_pitched_sfx(sfx, sfx_pitches[sfx_index])
	if sfx_index < sfx_pitches.size() - 1:
		sfx_index += 1
	else:
		sfx_pitches.shuffle()
		sfx_index = 0


func take_hit(power: int):
	shake_tween.start(shadow_animator)
	shake_tween.start(animator)
	play_pitched_sfx(hit_sfx)
	total_damage += power
	if total_damage >= starting_health:
		die()
		return


func die():
	is_dying = true
	if self is Placeable:
		animator.hide()
	else:
		animator.play()
		shadow_animator.play()
	if get_node_or_null("PhysicsCollider"):
		$PhysicsCollider.set_collision_layer(0)
	if get_node_or_null("LightOccluder2D"):
		$LightOccluder2D.occluder = null
	
	play_pitched_sfx(die_sfx.pick_random())
	drop_items()
	await animator.animation_finished
	queue_free()


func drop_items(remove: bool = true):
	var drop_base = get_parent().drop_base
	for i in num_drops:
		var drop: Drop = drop_base.instantiate()
		drop.initialize(Compendium.all_items[drop_types.pick_random()], position, drop_offsets[i % drop_offsets.size()])
		drops.push_front(drop)
	
	items_dropped.emit(drops, position, remove)


func do_action():
	print("no interaction")
