# npc.gd

extends CharacterBody2D
class_name NPC

const NUDGE: Vector2 = Vector2(0.003, 0.003)
var standing_offset: Vector2 = Vector2(8, 8)
var linear_movement_speed: int = 60
var facing: Vector2i
var holding: String = ""

@onready var npc_shadow: Sprite2D = $NPCShadow
@onready var sprite: Sprite2D = $Sprite2D
@onready var tool_animator:AnimatedSprite2D = $ToolAnimator
@onready var hold_sprite: ShadowedSprite = $HoldSprite

var npc_name: String

var current_animation: Array[String] = ["", ""]
var frame_timer: float
var current_frame: int

var schedule: Dictionary
var direction: Vector2i
var current_move_path: PackedVector2Array
var current_target_position: Vector2

enum STATE {STATIC, WANDERING, MIGRATING, MIGRATING_PAUSED}
var state: STATE = STATE.MIGRATING


func _ready():
	#knock position verrry slightly off-grid to prevent flickering while moving
	position -= NUDGE
	standing_offset += Vector2(randi_range(-4, 4), randi_range(-4, 4))
	
	set_current_animation("walk", "down")
	hold_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites, Vector2i(0, 2))
	end_hold()


func _physics_process(delta):
	npc_shadow.self_modulate = DayNightModulate.shadow_modulate
	animate(delta)
	
	match state:
		STATE.STATIC:
			stop_current_animation()
		
		STATE.WANDERING:
			pass
		
		STATE.MIGRATING:
			if current_move_path.is_empty():
				state = STATE.STATIC
				return
			
			direction = current_target_position - global_position
			global_position = global_position.move_toward(current_target_position, linear_movement_speed / 60.0)
			
			if (global_position - current_target_position).is_zero_approx():
				current_move_path.remove_at(0)
				new_target_position()
			
			if direction.x > 0:
				set_current_animation(holding + "walk", "right")
			elif direction.x < 0:
				set_current_animation(holding + "walk", "left")
			elif direction.y > 0:
				set_current_animation(holding + "walk", "down")
			elif direction.y < 0:
				set_current_animation(holding + "walk", "up")
			else:
				stop_current_animation()
		
		STATE.MIGRATING_PAUSED:
			stop_current_animation()


func new_target_position():
	if current_move_path.size() > 0:
		current_target_position = current_move_path[0] + standing_offset + NUDGE


func set_current_animation(anim_name: String, p_direction: String):
	if anim_name != current_animation.front():
		current_frame = 0
		sprite.set_texture(load("res://Art/npcs/" + npc_name + "/" + anim_name + ".png"))
	current_animation = [anim_name, p_direction]


func stop_current_animation():
	if current_animation.front() != "":
		current_frame = 0
		set_frame(current_animation, current_frame)
		current_animation = ["", ""]


func set_frame(animation: Array[String], frame_num: int):
	var direction_offset: int = NpcManager.DIRECTION_OFFSETS[animation[-1]]
	var anim_h_frames: int = NpcManager.ANIMATION_DATA[animation[0]][0]
	sprite.frame = anim_h_frames * direction_offset + (frame_num % anim_h_frames)


func animate(delta: float):
	if current_animation.front() != "":
		set_frame(current_animation, current_frame)
		frame_timer += delta
		if frame_timer > 1 / NpcManager.ANIMATION_DATA[current_animation.front()][2]:
			current_frame += 1
			frame_timer = 0


func set_move_path(new_move_path: PackedVector2Array):
	current_move_path = new_move_path
	new_target_position()


func face(p_direction: Vector2i):
	if p_direction.x > 0:
		set_frame([holding + "walk", "right"], 0)
	elif p_direction.x < 0:
		set_frame([holding + "walk", "left"], 0)
	elif p_direction.y > 0:
		set_frame([holding + "walk", "down"], 0)
	elif p_direction.y < 0:
		set_frame([holding + "walk", "up"], 0)


func start_hold(item: Item):
	holding = "hold_"
	hold_sprite.show()
	hold_sprite.change_frame(item.compendium_index)


func end_hold():
	holding = ""
	hold_sprite.hide()
