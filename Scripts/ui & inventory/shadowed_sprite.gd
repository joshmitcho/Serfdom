#shadowed_sprite.gd
extends Control
class_name ShadowedSprite

var main_sprite: Sprite2D
var shadow_sprite: Sprite2D


func initialize(spritesheet: Texture2D, num_sprites: Vector2i, separation = Vector2i(-1, 1)):
	main_sprite = $ShadowSprite/MainSprite
	main_sprite.texture = spritesheet
	main_sprite.hframes = int(num_sprites.x)
	main_sprite.vframes = int(num_sprites.y)
	
	shadow_sprite = $ShadowSprite
	shadow_sprite.texture = spritesheet
	shadow_sprite.hframes = int(num_sprites.x)
	shadow_sprite.vframes = int(num_sprites.y)
	shadow_sprite.offset = separation


func change_frame(p_frame: int):
	main_sprite.frame = p_frame
	shadow_sprite.frame = p_frame
