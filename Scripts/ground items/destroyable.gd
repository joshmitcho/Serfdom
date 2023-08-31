# destroyable.gd
extends Area2D
class_name Destroyable

signal destroyed(drops: Array[Drop], position: Vector2)

var object_name: StringName = "uninitialized_destroyable"
var compatible_tool_type: StringName = "none"
var starting_health: int = 1
var total_damage: int = 0

var drops: Array[Drop]
var drop_types: Array
var num_drops: int
var drop_offsets: Array = [-4, 4, 0, -8, 8, 0, -12, 12, -16, 16, -20, 20]

var die_sfx: Array = []
var hit_sfx
var sfx_pitches: Array = [0.8, 0.943874, 1.0, 1.059463, 1.122455]
var sfx_index: int = 0

var is_dying: bool = false
var is_tree: bool = false

@onready var animator = $AnimatedSprite2D
@onready var hit_sfx_player = $HitSFXPlayer
@onready var break_sfx_player = $BreakSFXPlayer

func _ready():
	get_parent().destroyables.append(self)
	scale = Vector2([1, -1].pick_random(), 1)

func initialize(p_name: StringName = "name"):
	sfx_pitches.shuffle()
	object_name = p_name
	animator.animation = object_name
	if object_name.substr(0, 4) == "tree":
		is_tree = true
	
	compatible_tool_type = Compendium.all_destroyables[object_name][0]
	starting_health = Compendium.all_destroyables[object_name][1]
	
	hit_sfx = Compendium.all_destroyables[object_name][2]
	die_sfx = Compendium.all_destroyables[object_name][3]
	
	var drop_odds = Compendium.all_destroyables[object_name][4]
	num_drops = int(drop_odds)
	if randf_range(0, 1) < (drop_odds - num_drops):
		num_drops += 1
	drop_types  = Compendium.all_destroyables[object_name][5]
	
	animator.offset.y = Compendium.all_destroyables[object_name][6]
	animator.modulate = Color.WHITE


func play_pitched_sfx(player, sfx):
	player.set_stream(sfx)
	player.set_pitch_scale(sfx_pitches[sfx_index])
	if sfx_index < sfx_pitches.size() - 1:
		sfx_index += 1
	else:
		sfx_pitches.shuffle()
		sfx_index = 0
	player.play()


func take_hit(power: int):
	$ShakeTween.start(animator)
	play_pitched_sfx(hit_sfx_player, hit_sfx)
	total_damage += power
	if total_damage >= starting_health:
		die()
		return


func die():
	is_dying = true
	if is_instance_of(self, Placeable):
		$AnimatedSprite2D.visible = false
	else:
		animator.play()
	if get_node_or_null("PhysicsCollider"):
		$PhysicsCollider.set_collision_layer(0)
	if get_node_or_null("LightOccluder2D"):
		$LightOccluder2D.occluder = null
	
	play_pitched_sfx(break_sfx_player, die_sfx.pick_random())
	
	get_parent().destroyables.erase(self)
	
	var drop_base = get_parent().drop_base
	for i in num_drops:
		var drop: Drop = drop_base.instantiate()
		drop.initialize(Compendium.all_items[drop_types.pick_random()], position, drop_offsets[i % drop_offsets.size()])
		drops.push_front(drop)
	
	emit_signal("destroyed", drops, position)
	await break_sfx_player.finished
	queue_free()


func do_action():
	print("no interaction")


func _on_invisibility_trigger_body_entered(body):
	if is_instance_of(body, Player) and is_tree:
		var tween = create_tween()
		tween.tween_property(animator, "modulate", Color(1, 1, 1, 0.5), 0.1)


func _on_invisibility_trigger_body_exited(body):
	if is_instance_of(body, Player) and is_tree:
		var tween = create_tween()
		tween.tween_property(animator, "modulate", Color.WHITE, 0.1)
