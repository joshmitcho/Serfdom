#shadowed_animated_sprite.gd
extends Node2D
class_name ShadowedAnimatedSprite

signal animation_finished()

@export var sprite_frames: SpriteFrames

var main_sprite: AnimatedSprite2D
var shadow_sprite: AnimatedSprite2D 


func load_animation(anim_name: StringName):
	main_sprite = $ShadowSprite/MainSprite
	shadow_sprite = $ShadowSprite
	main_sprite.sprite_frames = sprite_frames
	shadow_sprite.sprite_frames = sprite_frames
	main_sprite.animation = anim_name
	shadow_sprite.animation = anim_name


func load_offset(offset: int):
	main_sprite.offset.y = offset
	shadow_sprite.offset.y = offset


func set_frame(frame: int):
	main_sprite.set_frame_and_progress(frame, 0)
	shadow_sprite.set_frame_and_progress(frame, 0)


func play():
	main_sprite.play()
	shadow_sprite.play()
	await main_sprite.animation_finished
	animation_finished.emit()


func play_backwards():
	main_sprite.play_backwards()
	shadow_sprite.play_backwards()


func _physics_process(_delta):
	shadow_sprite.self_modulate = lerp(Color(1, 1, 1, 0.35), DayNightModulate.shadow_modulate, 0.5)
